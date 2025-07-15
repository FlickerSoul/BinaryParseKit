//
//  BinaryParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//
import BinaryParsing

public typealias Parsable = ExpressibleByParsing

public protocol EndianParsable {
    @lifetime(&input)
    init(parsing input: inout ParserSpan, endianness: Endianness) throws(ThrownParsingError)
}

public extension EndianParsable {
    init(
        parsing data: some RandomAccessCollection<UInt8>,
        endianness: BinaryParsing.Endianness
    ) throws(ThrownParsingError) {
        let result: Self?

        result = try data.withParserSpanIfAvailable {
            span throws(ThrownParsingError) in
            try Self(parsing: &span, endianness: endianness)
        }

        guard let result else {
            throw ParsingError(
                userError: BinaryParserKitError
                    .failedToParse("Failed to parse \(Self.self) from data.")
            )
        }

        self = result
    }
}

public protocol EndianSizedParsable {
    @lifetime(&input)
    init(parsing input: inout ParserSpan, endianness: Endianness, byteCount: Int) throws(ThrownParsingError)
}

public extension EndianSizedParsable {
    init(
        parsing data: some RandomAccessCollection<UInt8>,
        endianness: BinaryParsing.Endianness,
        byteCount: Int
    ) throws(ThrownParsingError) {
        let result: Self?

        result = try data.withParserSpanIfAvailable {
            span throws(ThrownParsingError) in
            try Self(parsing: &span, endianness: endianness, byteCount: byteCount)
        }

        guard let result else {
            throw ParsingError(
                userError: BinaryParserKitError
                    .failedToParse("Failed to parse \(Self.self) from data.")
            )
        }

        self = result
    }
}

public protocol SizedParsable {
    @lifetime(&input)
    init(parsing input: inout ParserSpan, byteCount: Int) throws(ThrownParsingError)
}

public extension SizedParsable {
    init(parsing data: some RandomAccessCollection<UInt8>, byteCount: Int) throws(ThrownParsingError) {
        let result: Self?

        result = try data.withParserSpanIfAvailable {
            span throws(ThrownParsingError) in
            try Self(parsing: &span, byteCount: byteCount)
        }

        guard let result else {
            throw ParsingError(
                userError: BinaryParserKitError
                    .failedToParse("Failed to parse \(Self.self) from data.")
            )
        }

        self = result
    }
}
