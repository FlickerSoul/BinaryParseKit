//
//  RawBitsSpan.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/8/26.
//

/// A non-escapable, non-copyable span representing a sequence of raw bits.
///
/// `RawBitsSpan` provides a view into a contiguous sequence of bytes with an associated bit count,
/// enabling efficient bit-level operations without allocating or copying data.
///
/// The bits are in MSB-first order, starting from `bitOffset` within the first byte of the underlying bytes.
///
/// Example:
/// ```swift
/// let data: [UInt8] = [0b1101_0000]
/// data.withUnsafeBytes { buffer in
///     let span = RawBitsSpan(RawSpan(buffer), bitOffset: 0, bitCount: 4)
///     // Represents the bits: 1, 1, 0, 1 (first 4 bits of 0b1101_0000)
/// }
/// ```
public struct RawBitsSpan: ~Escapable, ~Copyable {
    public typealias Buffer = Span<UInt8>

    /// The underlying byte span containing the raw bits.
    @usableFromInline
    private(set) var _bytes: Buffer

    /// The bit offset from the start of the buffer
    @usableFromInline
    private(set) var _bitOffset: Int

    /// The number of valid bits in the span.
    ///
    /// This value indicates how many bits from `bitOffset` are considered
    /// part of this bit sequence.
    @usableFromInline
    private(set) var _bitCount: Int

    /// The bit index where this RawBitsSpan starts (inclusive)
    ///
    /// This value is always between 0 and 7 (inclusive), representing the offset from the beginning of the first byte.
    @inlinable
    public var bitStartIndex: Int {
        _bitOffset % 8
    }

    /// The bit index where this RawBitsSpan ends (exclusive)
    ///
    /// Equals to ``bitStartIndex`` + ``bitCount``.
    @inlinable
    public var bitEndIndex: Int {
        bitStartIndex + _bitCount
    }

    /// Public accessor for underlying bytes.
    ///
    /// The bits are from in the range between ``bitStartIndex`` and ``bitEndIndex``
    public var bytes: Buffer {
        @inlinable
        @_lifetime(copy self)
        borrowing get {
            unsafe _bytes.extracting(unchecked: _bitOffset / 8 ..< (_bitOffset + _bitCount + 7) / 8)
        }
    }

    /// Public accessor for bit count.
    @inlinable
    public var bitCount: Int {
        _bitCount
    }

    /// The number of bytes of ``bitCount``
    ///
    /// Calculated as `(bitCount + 7) / 8`
    @inlinable
    public var byteCount: Int {
        (_bitCount + 7) / 8
    }

    /// The number of bytes used (touched/spanned) in the buffer
    @inlinable
    public var bufferByteCount: Int {
        (_bitCount + 7) / 8 + (bitStartIndex == 0 ? 0 : 1)
    }

    /// Creates a new raw bits span with a bit offset.
    ///
    /// - Parameters:
    ///   - bytes: The underlying byte span containing the raw bits
    ///   - bitOffset: The bit offset from the start (can be >= 8, will be normalized)
    ///   - bitCount: The number of valid bits in the span
    ///
    /// - Precondition: `bitOffset` must be non-negative
    /// - Precondition: `bitCount` must be non-negative
    /// - Precondition: The total bits (bitOffset + bitCount) must not exceed available bits in `bytes`
    @inlinable
    @_lifetime(copy bytes)
    public init(_ bytes: RawSpan, bitOffset: Int = 0, bitCount: Int) {
        precondition(bitOffset >= 0, "bitOffset must be non-negative")
        precondition(bitCount >= 0, "bitCount must be non-negative")
        precondition(
            bitOffset + bitCount <= bytes.byteCount * 8,
            "bitOffset + bitCount exceeds available bits in bytes",
        )

        self = .init(unchecked: (), bytes, bitOffset: bitOffset, bitCount: bitCount)
    }

    @inlinable
    @_lifetime(copy bytes)
    init(unchecked _: Void, _ bytes: RawSpan, bitOffset: Int, bitCount: Int) {
        self = .init(unchecked: (), Buffer(_bytes: bytes), bitOffset: bitOffset, bitCount: bitCount)
    }

    @inlinable
    @_lifetime(copy bytes)
    init(unchecked _: Void, _ bytes: Buffer, bitOffset: Int, bitCount: Int) {
        _bytes = bytes
        _bitOffset = bitOffset
        _bitCount = bitCount
    }

    @inlinable
    @_lifetime(copy other)
    public init(copying other: borrowing RawBitsSpan) {
        _bytes = other._bytes
        _bitOffset = other._bitOffset
        _bitCount = other._bitCount
    }

    /// Converts the bits to a fixed-width integer value.
    ///
    /// The bits are extracted in MSB-first order and returned right-aligned in the integer.
    /// Excess bits in the integer are masked to 0.
    ///
    /// - Parameters:
    ///   - type: The integer type to convert to (optional, can be inferred)
    ///   - bitCount: The number of bits to extract (optional, defaults to `T.bitCount`)
    /// - Returns: The extracted bits as a right-aligned integer
    ///
    /// Example:
    /// ```swift
    /// let data: [UInt8] = [0b1010_0000]
    /// data.withUnsafeBytes { buffer in
    ///     let span = RawBitsSpan(RawSpan(buffer), bitOffset: 0, bitCount: 4)
    ///     let value: UInt8 = try span.load() // Returns 0b0000_1010 (10)
    ///     let partial: UInt8 = try span.load(bitCount: 2) // Returns 0b0000_0010 (2)
    /// }
    /// ```
    @inlinable
    public borrowing func load<T: FixedWidthInteger>(as _: T.Type = T.self, bitCount: Int? = nil) throws -> T {
        let effectiveBitCount = Swift.min(bitCount ?? _bitCount, T.bitWidth)

        guard effectiveBitCount > 0 else { return 0 }

        // Validate that the requested bitCount doesn't exceed available bits
        guard effectiveBitCount <= _bitCount else {
            preconditionFailure("Requested bitCount (\(effectiveBitCount)) exceeds available bits (\(_bitCount))")
        }

        return loadUnsafe(as: T.self, bitCount: effectiveBitCount)
    }

    /// Loads bits as a fixed-width integer without bounds checking.
    ///
    /// This extracts bits starting from `_bitOffset` (which can be >= 8) in MSB-first order.
    ///
    /// - Parameters:
    ///   - type: The integer type to convert to (optional, can be inferred)
    ///   - bitCount: The number of bits to extract (optional, defaults to `I.bitCount`)
    /// - Returns: The extracted bits as a right-aligned integer
    @inlinable
    public borrowing func loadUnsafe<I: FixedWidthInteger>(as _: I.Type, bitCount: Int? = nil) -> I {
        let count = Swift.min(bitCount ?? _bitCount, I.bitWidth)
        precondition(count >= 0, "Count has to be grater than 0")

        guard count > 0 else { return 0 }

        let startByte = _bitOffset / 8
        let bitOffset = _bitOffset % 8
        let dataSpan = _bytes

        // For small extractions (up to 8 bits), use optimized single/double byte path
        if count <= 8 {
            var value: UInt8
            if bitOffset + count <= 8 {
                // Single byte extraction
                value = dataSpan[startByte]
                value <<= bitOffset
                value >>= (8 - count)
            } else {
                // Two byte extraction
                let highByte = dataSpan[startByte]
                let lowByte = dataSpan[startByte + 1]
                let combined = (UInt16(highByte) << 8) | UInt16(lowByte)
                value = UInt8((combined << bitOffset) >> (16 - count))
            }
            return I(value)
        }

        // For larger extractions, build the integer using << and | for speed
        var result: I = 0
        var bitsRemaining = count
        var currentByteIndex = startByte
        var currentBitOffset = bitOffset

        while bitsRemaining > 0 {
            let bitsInCurrentByte = min(8 - currentBitOffset, bitsRemaining)
            let byte = dataSpan[currentByteIndex]

            // Extract bits from this byte: shift left to clear leading bits, shift right to position
            // Keep operations in UInt8 space to ensure proper bit masking, then convert to I
            let extracted = I((byte << currentBitOffset) >> (8 - bitsInCurrentByte))

            // Add to result
            result = (result << bitsInCurrentByte) | extracted

            bitsRemaining -= bitsInCurrentByte
            currentByteIndex += 1
            currentBitOffset = 0
        }

        // The result is already right-aligned and masked by construction
        return result
    }

    // MARK: - Extracting (non-mutating)

    /// Returns a new `RawBitsSpan` containing the first `count` bits from this span.
    /// No bounds checking is performed.
    ///
    /// - Parameter count: The number of bits to extract from the start of the span
    /// - Returns: A new `RawBitsSpan` containing the first `count` bits
    @inlinable
    @_lifetime(borrow self)
    public borrowing func __extracting(unchecked _: Void, first count: Int) -> RawBitsSpan {
        RawBitsSpan(unchecked: (), _bytes, bitOffset: _bitOffset, bitCount: count)
    }

    /// Returns a new `RawBitsSpan` containing the last `count` bits from this span.
    /// No bounds checking is performed.
    ///
    /// - Parameter count: The number of bits to extract from the end of the span
    /// - Returns: A new `RawBitsSpan` containing the last `count` bits
    @inlinable
    @_lifetime(borrow self)
    public borrowing func __extracting(unchecked _: Void, last count: Int) -> RawBitsSpan {
        let newBitOffset = _bitOffset + (_bitCount - count)
        return RawBitsSpan(unchecked: (), _bytes, bitOffset: newBitOffset, bitCount: count)
    }

    /// Returns a new `RawBitsSpan` containing the first `count` bits from this span.
    ///
    /// - Parameter count: The number of bits to extract from the start of the span
    /// - Returns: A new `RawBitsSpan` containing the first `count` bits
    ///
    /// - Precondition: `count` must be non-negative and not exceed `self.bitCount`
    @inlinable
    @_lifetime(borrow self)
    public borrowing func extracting(first count: Int) -> RawBitsSpan {
        precondition(count >= 0, "count must be non-negative")
        precondition(count <= _bitCount, "count must not exceed available bits")
        return __extracting(unchecked: (), first: count)
    }

    /// Returns a new `RawBitsSpan` containing the last `count` bits from this span.
    ///
    /// - Parameter count: The number of bits to extract from the end of the span
    /// - Returns: A new `RawBitsSpan` containing the last `count` bits
    ///
    /// - Precondition: `count` must be non-negative and not exceed `self.bitCount`
    @inlinable
    @_lifetime(borrow self)
    public borrowing func extracting(last count: Int) -> RawBitsSpan {
        precondition(count >= 0, "count must be non-negative")
        precondition(count <= _bitCount, "count must not exceed available bits")
        return __extracting(unchecked: (), last: count)
    }

    // MARK: - Slicing (mutating)

    /// Removes and returns the first `count` bits from this span.
    /// No bounds checking is performed.
    ///
    /// After this call, `self` contains the remaining bits (original bits after the sliced portion).
    ///
    /// - Parameter count: The number of bits to slice from the start of the span
    /// - Returns: A new `RawBitsSpan` containing the sliced (first `count`) bits
    @inlinable
    @_lifetime(copy self)
    public mutating func __slicing(unchecked _: Void, first count: Int) -> RawBitsSpan {
        let sliced = RawBitsSpan(unchecked: (), _bytes, bitOffset: _bitOffset, bitCount: count)
        _bitOffset += count
        _bitCount -= count
        return sliced
    }

    /// Removes and returns the last `count` bits from this span.
    /// No bounds checking is performed.
    ///
    /// After this call, `self` contains the remaining bits (original bits before the sliced portion).
    ///
    /// - Parameter count: The number of bits to slice from the end of the span
    /// - Returns: A new `RawBitsSpan` containing the sliced (last `count`) bits
    @inlinable
    @_lifetime(copy self)
    public mutating func __slicing(unchecked _: Void, last count: Int) -> RawBitsSpan {
        let newBitOffset = _bitOffset + (_bitCount - count)
        let sliced = RawBitsSpan(unchecked: (), _bytes, bitOffset: newBitOffset, bitCount: count)
        _bitCount -= count
        return sliced
    }

    /// Removes and returns the first `count` bits from this span.
    ///
    /// After this call, `self` contains the remaining bits (original bits after the sliced portion).
    ///
    /// - Parameter count: The number of bits to slice from the start of the span
    /// - Returns: A new `RawBitsSpan` containing the sliced (first `count`) bits
    ///
    /// - Precondition: `count` must be non-negative and not exceed `self.bitCount`
    @inlinable
    @_lifetime(copy self)
    public mutating func slicing(first count: Int) -> RawBitsSpan {
        precondition(count >= 0, "count must be non-negative")
        precondition(count <= _bitCount, "count must not exceed available bits")
        return __slicing(unchecked: (), first: count)
    }

    /// Removes and returns the last `count` bits from this span.
    ///
    /// After this call, `self` contains the remaining bits (original bits before the sliced portion).
    ///
    /// - Parameter count: The number of bits to slice from the end of the span
    /// - Returns: A new `RawBitsSpan` containing the sliced (last `count`) bits
    ///
    /// - Precondition: `count` must be non-negative and not exceed `self.bitCount`
    @inlinable
    @_lifetime(copy self)
    public mutating func slicing(last count: Int) -> RawBitsSpan {
        precondition(count >= 0, "count must be non-negative")
        precondition(count <= _bitCount, "count must not exceed available bits")
        return __slicing(unchecked: (), last: count)
    }
}
