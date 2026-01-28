# ``BinaryParseKit``

A powerful Swift package for binary data parsing using macros and protocols.

## Overview

BinaryParseKit provides a convenient and type-safe way to parse binary data in Swift. It leverages Swift macros and protocols to automatically generate parsing logic for your data structures, making it easy to work with binary file formats, network protocols, and other binary data sources.

## Topics

### Get Started

- <doc:GetStarted>

### Printing

- <doc:ParsedPrinter>
- <doc:CustomPrinter>

### Struct Parsing Macros

- ``ParseStruct(bitEndian:parsingAccessor:printingAccessor:)``
- ``parse()``
- ``parse(byteCount:)``
- ``parse(endianness:)``
- ``parse(byteCount:endianness:)``
- ``parse(byteCountOf:)``
- ``parse(byteCountOf:endianness:)``
- ``parseRest()``
- ``parseRest(endianness:)``
- ``skip(byteCount:because:)``

### Enum Parsing Macros

- ``ParseEnum(bitEndian:parsingAccessor:printingAccessor:)``
- ``match()``
- ``match(byte:)``
- ``match(bytes:)``
- ``match(length:)``
- ``matchAndTake()``
- ``matchAndTake(byte:)``
- ``matchAndTake(bytes:)``
- ``matchDefault()``

### Bitmask Parsing Macros

- ``ParseBitmask(bitEndian:parsingAccessor:printingAccessor:)``
- ``mask()``
- ``mask(bitCount:)``
- ``RawBitsSpan``
- ``ExpressibleByRawBits``
- ``BitCountProviding``
- ``RawBits``
- ``RawBitsConvertible``
- ``BitmaskParsableError``

### Parsable Protocols

- ``Parsable``
- ``EndianParsable``
- ``SizedParsable``
- ``EndianSizedParsable``

### Matchable Protocols

- ``Matchable``

### Printable

- ``Printable``
- ``Printer``
- ``PrinterIntel``
- ``PrinterError``

### Printers

- ``ByteArrayPrinter``
- ``HexStringPrinter``
- ``HexStringPrinterFormatter``
- ``DefaultHexStringPrinterFormatter``
- ``DataPrinter``

### Error

- ``BinaryParserKitError``
