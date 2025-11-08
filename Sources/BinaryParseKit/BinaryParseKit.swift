// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported public import BinaryParseKitCommons
public import BinaryParsing

// MARK: - Skip Parsing

/// Skips a specified number of bytes during parsing.
///
/// Use this macro to skip over bytes in the binary data that are not needed for parsing,
/// such as padding, reserved fields, or alignment bytes.
///
/// - Parameters:
///   - byteCount: The number of bytes to skip
///   - because: A descriptive reason for skipping these bytes (used for documentation)
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct Header {
///     @parse(byteCount: 4)
///     let magic: UInt32
///
///     @skip(byteCount: 2, because: "reserved for future use")
///     @parse(byteCount: 2)
///     let version: UInt16
/// }
/// ```
@attached(peer)
public macro skip(byteCount: ByteCount, because: String) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

// MARK: - Field Parsing

/// Parses a field using the type's default `Parsable` implementation.
///
/// This macro marks a field for parsing using the type's built-in parsing behavior.
/// The field type must conform to `Parsable` protocol.
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct MyStruct {
///     @parse()
///     let value: UInt32  // Uses UInt32's default parsing
/// }
/// ```
@attached(peer)
public macro parse() = #externalMacro(module: "BinaryParseKitMacros", type: "EmptyPeerMacro")

/// Parses a field with a specific endianness.
///
/// Use this macro when you need to parse a field with a specific byte order
/// (big-endian or little-endian). The field type must conform to `EndianParsable`.
///
/// - Parameter endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct NetworkHeader {
///     @parse(endianness: .big)
///     let networkOrderValue: UInt32
///
///     @parse(endianness: .little)
///     let hostOrderValue: UInt32
/// }
/// ```
@attached(peer)
public macro parse(endianness: Endianness) = #externalMacro(module: "BinaryParseKitMacros", type: "EmptyPeerMacro")

/// Parses a field with a specific byte count.
///
/// Use this macro when you need to parse a field using a specific number of bytes.
/// The field type must conform to `SizedParsable`.
///
/// - Parameter byteCount: The number of bytes to read for this field
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct CompactHeader {
///     @parse(byteCount: 1)
///     let smallValue: UInt32  // Read only 1 byte for a UInt32
///
///     @parse(byteCount: 3)
///     let mediumValue: UInt64  // Read 3 bytes for a UInt64
/// }
/// ```
@attached(peer)
public macro parse(byteCount: ByteCount) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Parses a field with a byte count determined by another field's value.
///
/// Use this macro to create variable-length fields where the length is specified
/// by a previously parsed field. The field type must conform to `SizedParsable`.
///
/// - Parameter byteCountOf: A KeyPath to another field whose value determines the byte count
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///        The referenced field must be parsed before this field.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct VariableMessage {
///     @parse(byteCount: 2)
///     let length: UInt16
///
///     @parse(byteCountOf: \Self.length)
///     let data: Data  // Data length determined by the 'length' field
/// }
/// ```
@attached(peer)
public macro parse<R, V: BinaryInteger>(byteCountOf: KeyPath<R, V>) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Parses a field with both specific byte count and endianness.
///
/// Use this macro when you need precise control over both the number of bytes
/// and the byte order for parsing. The field type must conform to `EndianSizedParsable`.
///
/// - Parameters:
///   - byteCount: The number of bytes to read for this field
///   - endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct PreciseHeader {
///     @parse(byteCount: 3, endianness: .big)
///     let networkValue: UInt32  // Read 3 bytes in big-endian order
/// }
/// ```
@attached(peer)
public macro parse(byteCount: ByteCount, endianness: Endianness) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Parses a field with byte count from another field and specific endianness.
///
/// Combines variable-length parsing with endianness control. The field type
/// must conform to `EndianSizedParsable`.
///
/// - Parameters:
///   - byteCountOf: A KeyPath to another field whose value determines the byte count
///   - endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///        The referenced field must be parsed before this field.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct FlexibleNetworkPacket {
///     @parse(byteCount: 2, endianness: .big)
///     let payloadSize: UInt16
///
///     @parse(byteCountOf: \Self.payloadSize, endianness: .big)
///     let payload: Data  // Variable-length payload in network byte order
/// }
/// ```
@attached(peer)
public macro parse<R, V: BinaryInteger>(byteCountOf: KeyPath<R, V>, endianness: Endianness) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Parses all remaining bytes in the data stream.
///
/// Use this macro to parse all remaining bytes from the current position to the end
/// of the data. This is typically used for the last field in a structure.
/// The field type must conform to `SizedParsable`.
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///        Only one `@parseRest` field is allowed per struct, and it must be the last field.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct MessageWithPayload {
///     @parse(byteCount: 4)
///     let header: UInt32
///
///     @parseRest()
///     let payload: Data  // All remaining bytes
/// }
/// ```
@attached(peer)
public macro parseRest() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Parses all remaining bytes with a specific endianness.
///
/// Like `parseRest()`, but applies endianness conversion to the remaining data.
/// The field type must conform to `EndianSizedParsable`.
///
/// - Parameter endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///        Only one `@parseRest` field is allowed per struct, and it must be the last field.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct NetworkMessage {
///     @parse(byteCount: 2, endianness: .big)
///     let type: UInt16
///
///     @parseRest(endianness: .big)
///     let data: Data  // All remaining bytes in network byte order
/// }
/// ```
@attached(peer)
public macro parseRest(endianness: Endianness) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

// MARK: - Struct Parsing

/// Generates a `Parsable` implementation for a struct with annotated fields.
///
/// This macro analyzes the struct's fields marked with `@parse`, `@skip`, and `@parseRest`
/// macros and generates the necessary parsing code to read binary data into the struct.
///
/// The generated code includes:
/// - A `Parsable` conformance
/// - An initializer that reads from a `ParserSpan`
/// - Type validation functions to ensure fields conform to required protocols
/// - Proper error handling for parsing failures
///
/// - Note: All fields except those with accessors (`get` and `set`) must be parsed must be marked with `@parse`
/// variants.
///
/// Example:
/// ```swift
/// @ParseStruct
/// struct FileHeader {
///     @parse(byteCount: 4, endianness: .big)
///     let magic: UInt32
///
///     @parse(byteCount: 2, endianness: .little)
///     let version: UInt16
///
///     @skip(byteCount: 2, because: "reserved")
///     @parse(endianness: .little)
///     let fileSize: UInt32
/// }
///
/// // Usage:
/// let data = Data([0x89, 0x50, 0x4E, 0x47, 0x01, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00])
/// let header = try FileHeader(parsing: data)
/// ```
@attached(extension, conformances: BinaryParseKit.Parsable, names: arbitrary)
public macro ParseStruct() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ConstructStructParseMacro",
)

// MARK: - Parse Enum

@attached(extension, conformances: BinaryParseKit.Parsable, names: arbitrary)
public macro ParseEnum() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ConstructEnumParseMacro",
)

// MARK: - Enum Case Parsing

@attached(peer)
public macro match() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

@attached(peer)
public macro match(byte: UInt8) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

@attached(peer)
public macro match(bytes: [UInt8]) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)
