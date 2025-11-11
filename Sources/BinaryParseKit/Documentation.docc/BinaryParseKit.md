# ``BinaryParseKit``

A powerful Swift package for binary data parsing using macros and protocols.

## Overview

BinaryParseKit provides a convenient and type-safe way to parse binary data in Swift. It leverages Swift macros and protocols to automatically generate parsing logic for your data structures, making it easy to work with binary file formats, network protocols, and other binary data sources.

## Topics

### Articles

- <doc:Guide>

### Struct Parsing Macros

- ``ParseStruct()``
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

- ``ParseEnum()``
- ``match()``
- ``match(byte:)``
- ``match(bytes:)``
- ``matchAndTake()``
- ``matchAndTake(byte:)``
- ``matchAndTake(bytes:)``
- ``matchDefault()``

### Parsable Protocols

- ``Parsable``
- ``EndianParsable``
- ``SizedParsable``
- ``EndianSizedParsable``

### Matchable Protocols

- ``Matchable``
- ``MatchableRawRepresentable``

### Error

- ``BinaryParserKitError``
