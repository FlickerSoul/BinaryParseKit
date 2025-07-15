// The Swift Programming Language
// https://docs.swift.org/swift-book

import BinaryParseKitCommons
public import BinaryParsing

@attached(peer)
public macro skip(byteCount: ByteCount, because: String) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "SkipParsingMacro"
)

// MARK: - Struct Parsing

@attached(peer)
public macro parse() = #externalMacro(module: "BinaryParseKitMacros", type: "ByteParsingMacro")

@attached(peer)
public macro parse(endianness: Endianness) = #externalMacro(module: "BinaryParseKitMacros", type: "ByteParsingMacro")

@attached(peer)
public macro parse(byteCount: ByteCount) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(peer)
public macro parse<R, V: BinaryInteger>(byteCountOf: KeyPath<R, V>) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(peer)
public macro parse(byteCount: ByteCount, endianness: Endianness) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(peer)
public macro parse<R, V: BinaryInteger>(byteCountOf: KeyPath<R, V>, endianness: Endianness) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(peer)
public macro parseRest() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(peer)
public macro parseRest(endianness: Endianness) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(extension, conformances: BinaryParseKit.Parsable, names: arbitrary)
public macro ParseStruct() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ConstructStructParseMacro"
)
