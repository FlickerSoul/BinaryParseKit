# BinaryParseKit

A declarative Swift package for parsing binary data using macros, built on top of Apple's [`swift-binary-parsing`](https://github.com/apple/swift-binary-parsing) framework.

> [!IMPORTANT]
> This package is currently under active development and its APIs are subjected to drastic changes.

## Features

- **Declarative syntax**: Define binary structures using simple annotations
- **Type-safe parsing**: Leverages Swift's type system for safe binary data access
- **Flexible endianness**: Support for both big-endian and little-endian byte ordering
- **Variable-length fields**: Parse fields whose size depends on previously parsed values
- **Skip functionality**: Skip unwanted bytes with documentation
- **Custom byte counts**: Parse types with specific byte lengths
- **Remaining data parsing**: Parse all remaining bytes in a buffer

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

### Basic Parsing

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

### Parsing Macros

- **`@parse`** - Use the type's default parsing behavior
- **`@parse(endianness: .big/.little)`** - Parse with specific endianness
- **`@parse(byteCount: Int)`** - Parse a specific number of bytes
- **`@parse(byteCountOf: KeyPath)`** - Parse bytes based on another field's value
- **`@parseRest()`** - Parse all remaining bytes
- **`@skip(byteCount: Int, because: String)`** - Skip bytes with documentation

### Protocol Conformances

BinaryParseKit defines four parsing protocols:

- **`Parsable`** - Basic parsing without additional parameters
- **`EndianParsable`** - Parsing with endianness specification
- **`SizedParsable`** - Parsing with byte count specification
- **`EndianSizedParsable`** - Parsing with both endianness and byte count

Most built-in types already conform to these protocols. For custom types, implement the appropriate protocol(s).

### Variable-Length Fields

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

### Complex Structures

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

## Requirements

- Swift 6.2+
- Xcode 26.0+
- macOS 15.0+ / iOS 18.0+ / tvOS 18.0+ / watchOS 11.0+ / visionOS 2.0+

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

- **Enum parsing** - Support for parsing enums with associated values
- **More convenient APIs** - Shorter syntax and better autocomplete support
- **Advanced validation** - Runtime validation of parsing constraints
- **Performance optimizations** - Further optimization of generated parsing code

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
