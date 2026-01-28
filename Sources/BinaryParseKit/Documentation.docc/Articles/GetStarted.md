# Getting Started

`BinaryParseKit` is a Swift package that simplifies the process of parsing binary data by leveraging Swift's powerful macros and protocols. This guide will walk you through the basics of getting started with `BinaryParseKit`.

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

## Parsing

We have two byte parsing macros: ``ParseStruct(bitEndian:parsingAccessor:printingAccessor:)wwww`` and ``ParseEnum(bitEndian:parsingAccessor:printingAccessor:)``. They work together with decorative macros such as ``parse()``, ``match()``, ``skip(byteCount:because:)``, etc. In addition, we have ``ParseBitmask(bitEndian:parsingAccessor:printingAccessor:)`` to handle bitmask parsing.

### Parse Struct

#### Quick Example

Consider a binary packet with the following structure:

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

The declarative macros can be used are

- ``parse()``
- ``parse(endianness:)``
- ``parse(byteCount:)``
- ``parse(byteCount:endianness:)``
- ``parse(byteCountOf:)``
- ``parse(byteCountOf:endianness:)``
- ``parseRest()``
- ``parseRest(endianness:)``
- ``skip(byteCount:because:)``

### Parse Enum

#### Quick Example

With `RawValue` or specified bytes to match:

```swift
@ParseEnum
enum MessageType: UInt8 {
    @match
    case connect = 1

    @match(bytes: [0x02, 0x03])
    case data = 2

    @match(byte: 0xFF)
    case disconnect = 3
}

let msgType = try MessageType(parsing: Data([0x01]))
// msgType == .connect
```

Or with associated values

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

The idea is that each `case` should be decorated with at least one matching macro:

- ``match()``
- ``match(byte:)``
- ``match(bytes:)``
- ``matchAndTake(byte:)``
- ``matchAndTake(bytes:)``
- ``matchDefault()``

The difference between `match` and `matchAndTake` is that the former only matches the pattern, while the latter consumes the matched bytes from the input stream. For instance, take a input byte stream of

```
[1, 2, 3, 4, 5]
```

as an example. `match(bytes: [1, 2])` will check if the next two bytes are `1` and `2`, and the after `match` will still start from byte `1` at index 0. On the other hand, `matchAndTake(bytes: [1, 2])` will consume the first two bytes, and the after `matchAndTake` will start from byte `3` at index 2.

`matchDefault` behaves like `match` and does not consume any bytes. It is used as a fallback case when no other match patterns are satisfied. Only one `matchDefault` is allowed in an enum.
