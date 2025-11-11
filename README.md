# BinaryParseKit

A declarative Swift package for parsing binary data using macros, built on top of Apple's [`swift-binary-parsing`](https://github.com/apple/swift-binary-parsing) framework.

> [!IMPORTANT]
> Warning: This package is currently under active development and its APIs are subjected to drastic changes.

## Features

- **Declarative syntax**: Define binary structures using simple annotations
- **Type-safe parsing**: Leverages Swift's type system for safe binary data access
- **Flexible endianness**: Support for both big-endian and little-endian byte ordering
- **Variable-length fields**: Parse fields whose size depends on previously parsed values
- **Skip functionality**: Skip unwanted bytes with documentation
- **Custom byte counts**: Parse types with specific byte lengths
- **Remaining data parsing**: Parse all remaining bytes in a buffer
- **Enum parsing**: Parse enums with pattern matching and associated values

## Requirements

- Swift 6.2+
- Xcode 26.0+
- macOS 15.0+ / iOS 18.0+ / tvOS 18.0+ / watchOS 11.0+ / visionOS 2.0+

## Installation

### Swift Package Manager

Add BinaryParseKit to your project using Swift Package Manager. In Xcode, go to **File → Add Package Dependencies** and enter:

```
https://github.com/FlickerSoul/BinaryParseKit
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/FlickerSoul/BinaryParseKit", branch: "main")
]
```

## Quick Example

Consider a binary packet with the following structure:

```
+----------------------+----------------------+-------------------------------+
| packetIndex (1 byte) | packetCount (1 byte) |     SignalPacket (n bytes)    |
+----------------------+----------------------+-------------------------------+

+------------------------------------------------------------------+
|                         Signal Packet                            |
+---------------------+------------------+-------------------------+
| level (1 bytes)     | id (6 bytes)     | messageSize (1 byte)    |
+---------------------+------------------+-------------------------+
| message (variable, length = messageSize bytes)                   |
+------------------------------------------------------------------+
```

With BinaryParseKit, you can define and parse this structure declaratively:

```swift
import BinaryParseKit
import BinaryParsing

@ParseStruct
struct BluetoothPacket {
    @parse
    let packetIndex: UInt8
    @parse
    let packetCount: UInt8
    @parse
    let payload: SignalPacket
}

@ParseStruct
struct SignalPacket {
    @parse(byteCount: 1, endianness: .big)
    let level: UInt32
    @parse(byteCount: 6, endianness: .little)
    let id: UInt64
    @skip(byteCount: 1, because: "padding byte")
    @parse(endianness: .big)
    let messageSize: UInt8
    @parse(byteCountOf: \Self.messageSize)
    let message: String
}

// Extend String to support sized parsing
extension String: SizedParsable {
    public init(parsing input: inout BinaryParsing.ParserSpan, byteCount: Int) throws {
        try self.init(parsingUTF8: &input, count: byteCount)
    }
}
```

Parse binary data in one line:

```swift
let data: [UInt8] = [
    0x01, // packet index
    0x01, // packet count
    0xAA, // level
    0xAB, 0xAD, 0xC0, 0xFF, 0xEE, 0x00, // id (little endian)
    0x00, // padding byte (skipped)
    0x0C, // message size
    0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, 0x21 // "hello world!"
]

let packet = try BluetoothPacket(parsing: data)
print(packet.payload.message) // "hello world!"
```

## Usage

### Struct Parsing

#### Struct Parsing Macros

Mark your struct with `@ParseStruct` and annotate fields with parsing macros:

```swift
@ParseStruct
struct Header {
    @parse(endianness: .big)
    let magic: UInt32           // Uses default parsing

    @parse(endianness: .big)
    let version: UInt16         // Big-endian parsing

    @parse(byteCount: 3, endianness: .little)
    let customField: UInt32     // Parse only 3 bytes
}
```

Available struct parsing macros:

- **`@ParseStruct`** - Mark a struct for binary parsing
- **`@parse`** - Use the type's default parsing behavior
- **`@parse(endianness: .big/.little)`** - Parse with specific endianness
- **`@parse(byteCount: Int)`** - Parse a specific number of bytes
- **`@parse(byteCountOf: KeyPath)`** - Parse bytes based on another field's value
- **`@parseRest()`** - Parse all remaining bytes
- **`@skip(byteCount: Int, because: String)`** - Skip bytes with documentation

#### Variable-Length Fields

Parse fields whose length depends on previously parsed values:

```swift
@ParseStruct
struct VariableMessage {
    @parse
    let length: UInt8

    @parse(byteCountOf: \Self.length)
    let data: Data
}
```

Combine multiple techniques for complex binary formats:

```swift
@ParseStruct
struct ComplexPacket {
    @parse(byteCount: 4, endianness: .big)
    let header: UInt32

    @skip(byteCount: 2, because: "reserved field")
    @parse(endianness: .little)
    let payloadSize: UInt16

    @parse(byteCountOf: \Self.payloadSize, endianness: .big)
    let payload: Data

    @parseRest()
    let footer: Data
}
```

### Enum Parsing

#### Enum Parsing Macros

Parse enums with pattern matching and associated values using the `@ParseEnum` macro:

**Basic Enum Matching**

```swift
@ParseEnum
enum MessageType {
    @match(byte: 0x01)
    case connect

    @match(bytes: [0x02, 0x03])
    case data

    @match(byte: 0xFF)
    case disconnect
}

let msgType = try MessageType(parsing: Data([0x01]))
// msgType == .connect
```

**Enums with Associated Values**

Use `@matchAndTake` to consume the match pattern and `@parse` to parse associated values:

```swift
@ParseEnum
enum Command: Equatable {
    @matchAndTake(byte: 0x01)
    @parse(endianness: .big)
    case setValue(UInt16)

    @matchAndTake(byte: 0x02)
    @parse(endianness: .big)
    @parse(endianness: .big)
    case setRange(start: UInt16, end: UInt16)

    @matchAndTake(byte: 0xFF)
    case reset
}

let cmd = try Command(parsing: Data([0x01, 0x12, 0x34]))
// cmd == .setValue(0x1234)
```

**Raw Representable Enums**

For enums with raw values, conform to `MatchableRawRepresentable` (or `Matchable`):

```swift
@ParseEnum
enum StatusCode: UInt8, MatchableRawRepresentable {
    @match
    case success = 0x00

    @match
    case error

    @match
    case pending
}
```

**Default Cases**

Use `@matchDefault` to handle unrecognized values:

```swift
@ParseEnum
enum PacketType {
    @match(byte: 0x01)
    case known

    @matchDefault
    case unknown
}
```

Available enum parsing macros:

- **`@ParseEnum`** - Mark an enum for binary parsing
- **`@match(byte: UInt8)`** - Match a single byte
- **`@match(bytes: [UInt8])`** - Match a sequence of bytes, but doesn't shrink the remaining buffer
- **`@matchAndTake(byte:)`** and **`@matchAndTake(bytes:)`** - Match and consume bytes in the remaining buffer
- **`@matchDefault`** - Default case for unrecognized patterns, which doesn't consume any bytes in the remaining buffer
- **`@parse`** - Parse associated values (same options as struct fields)
- **`@skip`** - Skip bytes (same options as struct fields)

### Protocol Conformances

BinaryParseKit defines four parsing protocols:

- **`Parsable`** - Basic parsing without additional parameters
- **`EndianParsable`** - Parsing with endianness specification
- **`SizedParsable`** - Parsing with byte count specification
- **`EndianSizedParsable`** - Parsing with both endianness and byte count

Most built-in types already conform to these protocols. For custom types, implement the appropriate protocol(s).

In addition, as mentioned in the previous enum parsing section,
`Matchable` and `MatchableRawRepresentable` is introduced to allow each case to provide bytes for matching in the process.

## Contributing

BinaryParseKit is currently under active development and its API may face changes. Contributions, suggestions, and feedback are welcome!

### Issues & Suggestions

If you encounter any issues, have feature requests, or want to suggest improvements, please:

1. **Check existing issues** - Search through [existing issues](https://github.com/FlickerSoul/BinaryParseKit/issues) to see if your concern has already been reported
2. **Create a new issue** - If you don't find a related issue, feel free to [create a new one](https://github.com/FlickerSoul/BinaryParseKit/issues/new)
3. **Provide details** - Include as much relevant information as possible:
   - Swift version and platform
   - Code examples demonstrating the issue
   - Expected vs actual behavior
   - Use case or scenario description

### Future Directions

Some areas we're considering for future development:

- **More convenient APIs** - Shorter syntax and better autocomplete support, such as merging `ParseStruct` and `ParseEnum`
- **Advanced validation** - Runtime validation of parsing constraints, such as require minimal byte size checking in front instead of at each parsing
- **Performance optimizations** - Further optimization of generated parsing code, such as linear time enum matching for constant bytes provided (`O( max(n, m) )` instead of `O(n * m)`, where `n` is the number of cases and `m` is the max number of bytes provided for each case)
- **Porting to prio iOS/macOS 26** - because `Span` is introduced only in iOS/macOS 26, port of using `withUnsafePointer` can be provided to prior versions of OSes for better compatibility

Your feedback on these directions and other ideas is highly appreciated!

### Development

To contribute to BinaryParseKit:

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Submit a pull request

## License

See the LICENSE file for more info.

## Acknowledgments

- Built on top of Apple's [`swift-binary-parsing`](https://github.com/apple/swift-binary-parsing) framework
