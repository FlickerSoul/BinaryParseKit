//
//  RawBits.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/24/25.
//

import Foundation

/// A struct providing arbitrary-width bit storage for bitmask parsing operations.
///
/// `RawBits` stores a sequence of bits using `Data` for byte storage.
/// It provides operations for slicing, equality comparison, and bitwise operations.
public struct RawBits: Sendable {
    /// The number of valid bits stored.
    public private(set) var size: Int

    /// Number of bits per byte.
    private static let BitsPerWord = 8

    /// The underlying byte storage.
    public fileprivate(set) var data: Data

    /// Creates a RawBits instance from Data with a specified bit count.
    ///
    /// - Parameters:
    ///   - data: The underlying byte storage
    ///   - size: The number of valid bits (must be <= data.count * 8)
    public init(data: Data, size: Int) {
        precondition(size >= 0, "Size must be non-negative")
        precondition(size <= data.count * Self.BitsPerWord, "Size exceeds data capacity")

        // Calculate how many bytes we actually need
        let requiredBytes = (size + Self.BitsPerWord - 1) / Self.BitsPerWord

        if requiredBytes == 0 {
            self = .init(data: .init())
            return
        }

        // Trim to required bytes
        var normalizedData = Data(data.prefix(requiredBytes))

        // Zero out bits after the size limit
        let remainingBits = size % Self.BitsPerWord
        if remainingBits > 0 {
            // Mask the last byte to zero out unused bits
            // For MSB-first: keep the top `remainingBits` bits
            let mask: UInt8 = 0xFF << (Self.BitsPerWord - remainingBits)
            let lastIndex = normalizedData.count - 1
            normalizedData[lastIndex] &= mask
        }

        self.data = normalizedData
        self.size = size
    }

    /// Creates a RawBits instance from Data, using all bits.
    ///
    /// - Parameter data: The underlying byte storage
    public init(data: Data) {
        self.data = data
        size = data.count * Self.BitsPerWord
    }

    /// Creates an empty RawBits instance.
    public init() {
        data = Data()
        size = 0
    }

    /// The number of bytes needed to store the bits.
    public var byteCount: Int {
        (size + Self.BitsPerWord - 1) / Self.BitsPerWord
    }

    /// Extracts a single bit at the specified index (MSB-first ordering).
    ///
    /// - Parameter index: The bit index (0 is the most significant bit of the first byte)
    /// - Returns: `true` if the bit is 1, `false` if 0
    public func bit(at index: Int) -> Bool {
        precondition(index >= 0 && index < size, "Bit index out of range")
        let byteIndex = index / Self.BitsPerWord
        let bitOffset = index % Self.BitsPerWord
        let byte = data[data.startIndex + byteIndex]
        // MSB-first: bit 0 is the most significant bit (0x80)
        return (byte & (0x80 >> bitOffset)) != 0
    }

    /// Extracts bits from the specified range as a UInt64.
    ///
    /// - Parameters:
    ///   - start: The starting bit index (inclusive, MSB-first)
    ///   - count: The number of bits to extract (max 64)
    /// - Returns: The extracted bits as a UInt64, right-aligned
    public func extractBits(from start: Int, count: Int) -> UInt64 {
        precondition(start >= 0, "Start index must be non-negative")
        precondition(count >= 0 && count <= 64, "Count must be 0-64")
        precondition(start + count <= size, "Range exceeds size")

        if count == 0 { return 0 }

        var result: UInt64 = 0
        for i in 0 ..< count where bit(at: start + i) {
            result |= (1 << (count - 1 - i))
        }
        return result
    }
}

// MARK: - Slicing

public extension RawBits {
    /// Creates a new RawBits containing a contiguous range of bits.
    ///
    /// - Parameters:
    ///   - start: The starting bit index (inclusive)
    ///   - count: The number of bits to include
    /// - Returns: A new RawBits containing the specified bits
    func slice(from start: Int, count: Int) -> RawBits {
        precondition(start >= 0, "Start index must be non-negative")
        precondition(count >= 0, "Count must be non-negative")
        precondition(start + count <= size, "Slice range exceeds size")

        if count == 0 {
            return RawBits()
        }

        // Calculate how many bytes we need for the result
        let resultByteCount = (count + Self.BitsPerWord - 1) / Self.BitsPerWord
        var resultData = Data(repeating: 0, count: resultByteCount)

        // Copy bits one by one to ensure proper alignment
        for i in 0 ..< count where bit(at: start + i) {
            let byteIndex = i / Self.BitsPerWord
            let bitOffset = i % Self.BitsPerWord
            // MSB-first: bit 0 is the most significant bit (0x80)
            resultData[byteIndex] |= (0x80 >> bitOffset)
        }

        return RawBits(data: resultData, size: count)
    }
}

// MARK: - Equality

extension RawBits: Equatable {
    public static func == (lhs: RawBits, rhs: RawBits) -> Bool {
        guard lhs.size == rhs.size else { return false }

        // Compare byte by byte, masking the last byte if needed
        let fullBytes = lhs.size / BitsPerWord
        let remainingBits = lhs.size % BitsPerWord

        for i in 0 ..< fullBytes {
            let lhsByte = lhs.data[lhs.data.startIndex + i]
            let rhsByte = rhs.data[rhs.data.startIndex + i]
            if lhsByte != rhsByte { return false }
        }

        if remainingBits > 0 {
            let lhsByte = lhs.data[lhs.data.startIndex + fullBytes]
            let rhsByte = rhs.data[rhs.data.startIndex + fullBytes]
            // Mask to only compare the valid bits (MSB-first)
            let mask: UInt8 = 0xFF << (8 - remainingBits)
            if (lhsByte & mask) != (rhsByte & mask) { return false }
        }

        return true
    }
}

// MARK: - Slice Equality with Offset

public extension RawBits {
    /// Compares a portion of this RawBits against another RawBits.
    ///
    /// - Parameters:
    ///   - other: The RawBits to compare against
    ///   - offset: The starting bit offset in this RawBits
    ///   - length: The number of bits to compare
    /// - Returns: `true` if the bits match
    func sliceEquals(_ other: RawBits, at offset: Int = 0) -> Bool {
        precondition(offset >= 0, "Offset must be non-negative")
        precondition(offset + other.size <= size, "Range exceeds size")

        for i in 0 ..< other.size where bit(at: offset + i) != other.bit(at: i) {
            return false
        }
        return true
    }
}

// MARK: - Bitwise Operations

public extension RawBits {
    /// Performs bitwise AND with another RawBits.
    ///
    /// The result size is the minimum of the two operand sizes.
    static func & (lhs: RawBits, rhs: RawBits) -> [UInt8] {
        let resultSize = min(lhs.size, rhs.size)
        let byteCount = (resultSize + BitsPerWord - 1) / BitsPerWord

        var result = [UInt8](repeating: 0, count: byteCount)
        for i in 0 ..< byteCount {
            let lhsByte = lhs.data[lhs.data.startIndex + i]
            let rhsByte = rhs.data[rhs.data.startIndex + i]
            result[i] = lhsByte & rhsByte
        }

        // Mask the last byte if needed
        let remainingBits = resultSize % BitsPerWord
        if remainingBits > 0, byteCount > 0 {
            let mask: UInt8 = 0xFF << (8 - remainingBits)
            result[byteCount - 1] &= mask
        }

        return result
    }

    /// Performs bitwise OR with another RawBits.
    ///
    /// The result size is the minimum of the two operand sizes.
    static func | (lhs: RawBits, rhs: RawBits) -> [UInt8] {
        let resultSize = min(lhs.size, rhs.size)
        let byteCount = (resultSize + BitsPerWord - 1) / BitsPerWord

        var result = [UInt8](repeating: 0, count: byteCount)
        for i in 0 ..< byteCount {
            let lhsByte = lhs.data[lhs.data.startIndex + i]
            let rhsByte = rhs.data[rhs.data.startIndex + i]
            result[i] = lhsByte | rhsByte
        }

        // Mask the last byte if needed
        let remainingBits = resultSize % BitsPerWord
        if remainingBits > 0, byteCount > 0 {
            let mask: UInt8 = 0xFF << (8 - remainingBits)
            result[byteCount - 1] &= mask
        }

        return result
    }

    /// Performs bitwise XOR with another RawBits.
    ///
    /// The result size is the minimum of the two operand sizes.
    static func ^ (lhs: RawBits, rhs: RawBits) -> [UInt8] {
        let resultSize = min(lhs.size, rhs.size)
        let byteCount = (resultSize + BitsPerWord - 1) / BitsPerWord

        var result = [UInt8](repeating: 0, count: byteCount)
        for i in 0 ..< byteCount {
            let lhsByte = lhs.data[lhs.data.startIndex + i]
            let rhsByte = rhs.data[rhs.data.startIndex + i]
            result[i] = lhsByte ^ rhsByte
        }

        // Mask the last byte if needed
        let remainingBits = resultSize % BitsPerWord
        if remainingBits > 0, byteCount > 0 {
            let mask: UInt8 = 0xFF << (8 - remainingBits)
            result[byteCount - 1] &= mask
        }

        return result
    }
}
