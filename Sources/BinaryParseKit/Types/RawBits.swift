//
//  RawBits.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/24/25.
//

import Foundation

/// A struct providing arbitrary-width bit storage for bitmask printing.
///
/// `RawBits` stores a sequence of bits using `Data` for byte storage.
/// It provides operations for equality comparison and appending.
/// It's currently not optimized, and can be improved later.
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
