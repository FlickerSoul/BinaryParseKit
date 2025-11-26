// The Swift Programming Language
// https://docs.swift.org/swift-book

import BinaryParseKitCommons
import BinaryParsing

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
/// - Note: This macro has no effect on its own unless used alongside `@ParseStruct` on struct fields.
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

/// Parses a field that conforms to ``Parsable``.
///
/// This macro marks a field for parsing using the type's built-in parsing behavior.
/// The field type must conform to ``Parsable`` protocol.
///
/// - Note: This macro has no effect on its own unless used alongside `@ParseStruct` on struct fields.
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
/// (big-endian or little-endian). The field type must conform to ``EndianParsable``.
///
/// - Parameter endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro has no effect on its own unless used alongside `@ParseStruct` on struct fields.
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

/// Parses a field that conforms to ``SizedParsable`` with a specific byte count.
///
/// Use this macro when you need to parse a field using a specific number of bytes.
/// The field type must conform to ``SizedParsable``.
///
/// - Parameter byteCount: The number of bytes to read for this field
///
/// - Note: This macro has no effect on its own unless used alongside `@ParseStruct` on struct fields.
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

/// Parses a field that conforms to ``SizedParsable`` with a byte count determined by another field's value
///
/// Use this macro to create variable-length fields where the length is specified
/// by a previously parsed field. The field type must conform to ``SizedParsable``.
///
/// - Parameter byteCountOf: A KeyPath to another field whose value determines the byte count
///
/// - Note: This macro has no effect on its own unless used alongside `@ParseStruct` on struct fields.
///
/// - Important: The referenced field in `byteCountOf` must be parsed before this field.
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

/// Parses a field that conforms to ``EndianSizedParsable`` with both specific byte count and endianness.
///
/// Use this macro when you need precise control over both the number of bytes
/// and the byte order for parsing. The field type must conform to ``EndianSizedParsable``.
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

/// Parses a field that conforms to ``EndianSizedParsable`` with byte count from another field and specific endianness.
///
/// Combines variable-length parsing with endianness control. The field type
/// must conform to ``EndianSizedParsable``.
///
/// - Parameters:
///   - byteCountOf: A KeyPath to another field whose value determines the byte count
///   - endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro has no effect on its own unless used alongside `@ParseStruct` on struct fields.
///
/// - Important: The referenced field in `byteCountOf` must be parsed before this field.
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
/// The field type must conform to ``SizedParsable``.
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// - Note: Only one `@parseRest` field is allowed per struct, and it must be the last field.
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
/// The field type must conform to ``EndianSizedParsable``.
///
/// - Parameter endianness: The byte order to use for parsing (`.big` or `.little`)
///
/// - Note: This macro must be used alongside `@ParseStruct` on struct fields.
///
/// - Note: Only one `@parseRest` field is allowed per struct, and it must be the last field.
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

/// Generates a ``Parsable`` implementation for a struct with annotated fields.
///
/// This macro analyzes the struct's fields marked with `@parse`, `@skip`, and `@parseRest`
/// macros and generates the necessary parsing code to read binary data into the struct.
///
/// The generated code includes:
/// - A ``Parsable`` conformance
/// - Type validation functions to ensure fields conform to required protocols
/// - Proper error handling for parsing failures
/// - A ``Printable`` conformance
///
/// - Parameters:
///   - parsingAccessor: The accessor level for the generated `Parsable` conformance (default is `.follow`)
///   - printingAccessor: The accessor level for the generated `Printable` conformance (default is `.follow`)
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
@attached(extension, conformances: BinaryParseKit.Parsable, BinaryParseKit.Printable, names: arbitrary)
public macro ParseStruct(
    parsingAccessor: ExtensionAccessor = .follow,
    printingAccessor: ExtensionAccessor = .follow,
) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ConstructStructParseMacro",
)

// MARK: - Parse Enum

/// Generates a ``Parsable`` implementation for an enum with annotated cases.
///
/// This macro analyzes the enum's cases marked with `@match`, `@matchAndTake`, and `@matchDefault` with optional
/// associated values,
/// whose parsing can be specified using ``parse(byteCount:)``  and ``skip(byteCount:because:)`` macros.
///
/// The generated code includes:
/// - A ``Parsable`` conformance
/// - A ``Printable`` conformance
///
/// - Parameters:
///   - parsingAccessor: The accessor level for the generated `Parsable` conformance (default is `.follow`)
///   - printingAccessor: The accessor level for the generated `Printable` conformance (default is `.follow`)
///
/// - Note: All enum cases must be marked with `@match` variants, which is intentional by design, which I don't think is
/// necessary and is possible to be lifted int the future.
/// - Note: Only one `@matchDefault` case is allowed per enum, and has to be declared at the end of all other cases.
/// - Note: any `match` macro has to proceed `parse` and `skip` macros.
@attached(extension, conformances: BinaryParseKit.Parsable, BinaryParseKit.Printable, names: arbitrary)
public macro ParseEnum(
    parsingAccessor: ExtensionAccessor = .follow,
    printingAccessor: ExtensionAccessor = .follow,
) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ConstructEnumParseMacro",
)

// MARK: - Enum Case Parsing

/// Defines a match case using the enum's raw value without consuming bytes from the buffer.
///
/// Use this macro for ``Matchable`` enums where each case's raw value
/// serves as the match pattern. The matched bytes are NOT consumed from the buffer.
///
/// - Note: This declaration can only be used when the enum conforms to ``Matchable`` protocol.
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum StatusCode: UInt8, Matchable {
///     @match
///     case success = 0x00  // Matches byte 0x00 without advancing the pointer
///
///     @match
///     case error = 0x01    // Matches byte 0x01 without advancing the pointer
/// }
///
/// let status = try StatusCode(parsing: Data([0x00]))
/// // status == .success, buffer pointer remains at 0x00
/// ```
@attached(peer)
public macro match() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Matches a single byte pattern without consuming it from the buffer.
///
/// Use this macro to match a specific byte value. The matched byte is NOT consumed,
/// allowing it to be used by subsequent parsing operations.
///
/// - Parameter byte: The byte value to match (0x00 - 0xFF)
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum MessageType {
///     @match(byte: 0x01)
///     case ping  // Matches 0x01 without advancing the pointer
///
///     @match(byte: 0x02)
///     case pong  // Matches 0x02 without advancing the pointer
/// }
///
/// let msg = try MessageType(parsing: Data([0x01]))
/// // msg == .ping, buffer pointer remains at 0x01
/// ```
@attached(peer)
public macro match(byte: UInt8) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Matches a sequence of bytes without consuming them from the buffer.
///
/// Use this macro to match a specific byte pattern. The matched bytes are NOT consumed,
/// allowing them to be used by subsequent parsing operations.
///
/// - Parameter bytes: The byte sequence to match
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum FrameType {
///     @match(bytes: [0xFF, 0xD8])
///     case jpegHeader  // Matches JPEG magic bytes without advancing the pointer
///
///     @match(bytes: [0x89, 0x50, 0x4E, 0x47])
///     case pngHeader   // Matches PNG magic bytes without advancing the pointer
/// }
///
/// let frame = try FrameType(parsing: Data([0xFF, 0xD8]))
/// // frame == .jpegHeader, buffer pointer remains at 0xFF
/// ```
@attached(peer)
public macro match(bytes: [UInt8]) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Matches and consumes bytes from the buffer using the enum's raw value.
///
/// Use this macro for ``Matchable`` enums where each case's raw value
/// serves as the match pattern. The matched bytes ARE consumed from the buffer,
/// making this suitable for cases with associated values that need to parse subsequent data.
///
/// - Note: This declaration can only be used when the enum conforms to ``Matchable`` protocol.
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum Command: UInt8, Matchable {
///     @matchAndTake
///     @parse(endianness: .big)
///     case setValue(UInt16) = 0x01  // Matches and consumes 0x01, then parses UInt16
///
///     @matchAndTake
///     @parse(endianness: .big)
///     case getValue(UInt16) = 0x02  // Matches and consumes 0x02, then parses UInt16
/// }
///
/// let cmd = try Command(parsing: Data([0x01, 0x12, 0x34]))
/// // cmd == .setValue(0x1234)
/// ```
@attached(peer)
public macro matchAndTake() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Matches and consumes a single byte from the buffer.
///
/// Use this macro to match a specific byte value and remove it from the buffer.
/// This is typically used before parsing associated values, allowing the subsequent
/// data to be parsed without the match byte.
///
/// - Parameter byte: The byte value to match and consume (0x00 - 0xFF)
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum Packet: Equatable {
///     @matchAndTake(byte: 0x01)
///     @parse(endianness: .big)
///     case data(UInt32)  // Matches 0x01, consumes it, then parses UInt32
///
///     @matchAndTake(byte: 0xFF)
///     case terminate     // Matches and consumes 0xFF
/// }
///
/// let packet = try Packet(parsing: Data([0x01, 0x12, 0x34, 0x56, 0x78]))
/// // packet == .data(0x12345678)
/// ```
@attached(peer)
public macro matchAndTake(byte: UInt8) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Matches and consumes a sequence of bytes from the buffer.
///
/// Use this macro to match a specific byte pattern and remove it from the buffer.
/// This is useful for protocol headers or magic numbers that precede payload data.
///
/// - Parameter bytes: The byte sequence to match and consume
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum Protocol: Equatable {
///     @matchAndTake(bytes: [0xCA, 0xFE])
///     @parse(endianness: .big)
///     case messageV1(UInt32)  // Matches [0xCA, 0xFE], consumes them, parses UInt32
///
///     @matchAndTake(bytes: [0xDE, 0xAD, 0xBE, 0xEF])
///     @parse(endianness: .big)
///     case messageV2(UInt64)  // Matches [0xDE, 0xAD, 0xBE, 0xEF], consumes them, parses UInt64
/// }
///
/// let proto = try Protocol(parsing: Data([0xCA, 0xFE, 0x12, 0x34, 0x56, 0x78]))
/// // proto == .messageV1(0x12345678)
/// ```
@attached(peer)
public macro matchAndTake(bytes: [UInt8]) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)

/// Defines a default case for enum parsing when no other cases match.
///
/// Use this macro to handle any byte patterns that don't match the explicit cases.
/// The buffer pointer remains at the current position and does not advance.
///
/// - Note: Only one `@matchDefault` case is allowed per enum, and it must be declared at the end of all other cases.
///
/// Example:
/// ```swift
/// @ParseEnum
/// enum PacketType {
///     @match(byte: 0x01)
///     case data
///
///     @match(byte: 0x02)
///     case control
///
///     @matchDefault
///     case unknown  // Matches any other byte value
/// }
///
/// let packet1 = try PacketType(parsing: Data([0x01]))
/// // packet1 == .data, buffer pointer remains at 0x01
///
/// let packet2 = try PacketType(parsing: Data([0xFF]))
/// // packet2 == .unknown, buffer pointer remains at 0xFF
/// ```
///
/// Example with associated values:
/// ```swift
/// @ParseEnum
/// enum Command: Equatable {
///     @matchAndTake(byte: 0x01)
///     @parse(endianness: .big)
///     case knownCommand(UInt16)
///
///     @matchDefault
///     @parse(endianness: .big)
///     case unknownCommand(UInt16)
/// }
///
/// let cmd = try Command(parsing: Data([0xFF, 0x12, 0x34]))
/// // cmd == .unknownCommand(0xFF12)
/// ```
@attached(peer)
public macro matchDefault() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "EmptyPeerMacro",
)
