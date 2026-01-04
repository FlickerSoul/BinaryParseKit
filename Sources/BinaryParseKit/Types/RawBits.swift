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
    public let size: Int

    /// Number of bits per byte.
    private static let BitsPerWord = 8

    /// The underlying byte storage.
    public let data: Data

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
            self = .init()
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
        self = .init(data: .init())
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
    public func extractBits(from start: Int, count: Int) -> UInt8 {
        precondition(start >= 0, "Start index must be non-negative")
        precondition(count >= 0 && count <= 8, "Count must be 0-64")
        precondition(start + count <= size, "Range exceeds size")

        if count == 0 { return 0 }

        let startByte = start / Self.BitsPerWord
        let bitOffset = start % Self.BitsPerWord
        let bytesSpanned = (count + (Self.BitsPerWord - 1)) / Self.BitsPerWord

        let dataSpan = data.bytes

        if bytesSpanned == 1 {
            var value = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte, as: UInt8.self)
            value <<= bitOffset
            value >>= (8 - count)
            return value
        } else {
            // Slow path: need 9 bytes (bitOffset > 0 and count = 64)
            var highValue = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte, as: UInt8.self)
            let lowByte = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte + Self.BitsPerWord, as: UInt8.self)

            highValue <<= bitOffset
            highValue |= lowByte >> (Self.BitsPerWord - bitOffset)
            return highValue
        }
    }
}

// MARK: - Concatenation

public extension RawBits {
    /// Appends another RawBits to this one, returning a new combined RawBits.
    ///
    /// The bits from `other` are placed immediately after the bits of `self`,
    /// maintaining MSB-first ordering.
    ///
    /// - Parameter other: The RawBits to append
    /// - Returns: A new RawBits containing both bit sequences
    func appending(_ other: RawBits) -> RawBits {
        if size == 0 {
            return other
        }
        if other.size == 0 {
            return self
        }

        let totalSize = size + other.size
        let resultByteCount = (totalSize + Self.BitsPerWord - 1) / Self.BitsPerWord
        var resultData = Data(repeating: 0, count: resultByteCount)

        // Copy self's bytes
        let selfByteCount = (size + Self.BitsPerWord - 1) / Self.BitsPerWord
        for i in 0 ..< selfByteCount {
            resultData[i] = data[data.startIndex + i]
        }

        // Calculate where to start appending other's bits
        let bitOffset = size % Self.BitsPerWord

        if bitOffset == 0 {
            // Byte-aligned: just copy other's bytes
            let otherByteCount = (other.size + Self.BitsPerWord - 1) / Self.BitsPerWord
            for i in 0 ..< otherByteCount {
                resultData[selfByteCount + i] = other.data[other.data.startIndex + i]
            }
        } else {
            // Non-aligned: need to shift and merge
            let otherByteCount = (other.size + Self.BitsPerWord - 1) / Self.BitsPerWord
            var destIndex = selfByteCount - 1

            for i in 0 ..< otherByteCount {
                let otherByte = other.data[other.data.startIndex + i]
                // High bits go into current byte
                resultData[destIndex] |= otherByte >> bitOffset
                // Low bits go into next byte
                destIndex += 1
                if destIndex < resultByteCount {
                    resultData[destIndex] = otherByte << (Self.BitsPerWord - bitOffset)
                }
            }
        }

        return RawBits(data: resultData, size: totalSize)
    }

    /// Concatenates multiple RawBits instances into one.
    ///
    /// - Parameter bits: The RawBits instances to concatenate
    /// - Returns: A new RawBits containing all bit sequences in order
    static func concatenate(_ bits: [RawBits]) -> RawBits {
        bits.reduce(RawBits()) { $0.appending($1) }
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

        let resultByteCount = (count + Self.BitsPerWord - 1) / Self.BitsPerWord
        var resultData = Data(repeating: 0, count: resultByteCount)

        let startByte = start / Self.BitsPerWord
        let bitOffset = start % Self.BitsPerWord
        let dataSpan = data.bytes

        if bitOffset == 0 {
            // Fast path: byte-aligned, just copy bytes
            for i in 0 ..< resultByteCount {
                resultData[i] = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte + i, as: UInt8.self)
            }
        } else {
            // Combine bytes with shifting, loading each byte only once
            var i = 0
            var currentByte = unsafe dataSpan.unsafeLoad(fromByteOffset: startByte, as: UInt8.self)

            while i < resultByteCount {
                var value = currentByte << bitOffset

                let nextByteIndex = startByte + i + 1
                if nextByteIndex < data.count {
                    let nextByte = unsafe dataSpan.unsafeLoad(fromByteOffset: nextByteIndex, as: UInt8.self)
                    value |= nextByte >> (Self.BitsPerWord - bitOffset)
                    currentByte = nextByte
                }

                resultData[i] = value
                i += 1
            }
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
    /// - Returns: `true` if the bits match
    func sliceEquals(_ other: RawBits, at offset: Int = 0) -> Bool {
        precondition(offset >= 0, "Offset must be non-negative")
        precondition(offset + other.size <= size, "Range exceeds size")

        if other.size == 0 {
            return true
        }

        let startByte = offset / Self.BitsPerWord
        let bitOffset = offset % Self.BitsPerWord

        let fullBytes = other.size / Self.BitsPerWord
        let remainingBits = other.size % Self.BitsPerWord

        if bitOffset == 0 {
            // Fast path: byte-aligned, direct comparison
            for i in 0 ..< fullBytes
                where data[data.startIndex + startByte + i] != other.data[other.data.startIndex + i] {
                return false
            }

            // Compare tail (remaining bits)
            if remainingBits > 0 {
                let selfByte = data[data.startIndex + startByte + fullBytes]
                let otherByte = other.data[other.data.startIndex + fullBytes]
                let mask: UInt8 = 0xFF << (Self.BitsPerWord - remainingBits)
                if (selfByte & mask) != (otherByte & mask) { return false }
            }
        } else {
            // Non-aligned: shift self's bytes to align with other
            let selfSpan = data.bytes
            var i = 0
            var currentByte = unsafe selfSpan.unsafeLoad(fromByteOffset: startByte, as: UInt8.self)

            // Compare middle (full bytes)
            while i < fullBytes {
                var selfValue = currentByte << bitOffset

                let nextByteIndex = startByte + i + 1
                if nextByteIndex < data.count {
                    let nextByte = unsafe selfSpan.unsafeLoad(fromByteOffset: nextByteIndex, as: UInt8.self)
                    selfValue |= nextByte >> (Self.BitsPerWord - bitOffset)
                    currentByte = nextByte
                }

                if selfValue != other.data[other.data.startIndex + i] { return false }
                i += 1
            }

            // Compare tail (remaining bits)
            if remainingBits > 0 {
                var selfValue = currentByte << bitOffset

                let nextByteIndex = startByte + i + 1
                if nextByteIndex < data.count {
                    let nextByte = unsafe selfSpan.unsafeLoad(fromByteOffset: nextByteIndex, as: UInt8.self)
                    selfValue |= nextByte >> (Self.BitsPerWord - bitOffset)
                }

                let otherByte = other.data[other.data.startIndex + fullBytes]
                let mask: UInt8 = 0xFF << (Self.BitsPerWord - remainingBits)
                if (selfValue & mask) != (otherByte & mask) { return false }
            }
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
