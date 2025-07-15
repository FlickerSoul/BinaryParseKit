// The Swift Programming Language
// https://docs.swift.org/swift-book

import BinaryParsing
import Foundation

public typealias ByteCount = Int

@attached(peer)
public macro skip(_ count: ByteCount, because: String) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "SkipParsingMacro"
)

// MARK: - Struct Parsing

@attached(peer)
public macro parse() = #externalMacro(module: "BinaryParseKitMacros", type: "ByteParsingMacro")

@attached(peer)
public macro parse(_ count: ByteCount) = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ByteParsingMacro"
)

@attached(peer)
public macro parse(_ count: ByteCount, endianness: Endianness) = #externalMacro(
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

@attached(extension, names: arbitrary)
public macro ParseStruct() = #externalMacro(
    module: "BinaryParseKitMacros",
    type: "ConstructParseStructMacro"
)
