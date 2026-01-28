//
//  BenchmarkTypesTests.swift
//  BinaryParseKit
//
//  Tests for BenchmarkTypes types.
//

import BenchmarkTypes
import BinaryParseKit
import Foundation
import Testing

@Suite("Benchmark Types Tests")
struct BenchmarkTypesTests {
    // MARK: - Simple Enum Tests

    @Test("Parse simple enum - first case")
    func parseSimpleEnumFirst() throws {
        let data = Data([0x01])
        let parsed = try BenchmarkEnumSimple(parsing: data)
        let baseline = BenchmarkEnumSimple.parseBaseline(data)
        #expect(parsed == .first)
        #expect(parsed == baseline)
    }

    @Test("Parse simple enum - second case")
    func parseSimpleEnumSecond() throws {
        let data = Data([0x02])
        let parsed = try BenchmarkEnumSimple(parsing: data)
        let baseline = BenchmarkEnumSimple.parseBaseline(data)
        #expect(parsed == .second)
        #expect(parsed == baseline)
    }

    @Test("Parse simple enum - third case")
    func parseSimpleEnumThird() throws {
        let data = Data([0x03])
        let parsed = try BenchmarkEnumSimple(parsing: data)
        let baseline = BenchmarkEnumSimple.parseBaseline(data)
        #expect(parsed == .third)
        #expect(parsed == baseline)
    }

    // MARK: - Complex Enum Tests

    @Test("Parse complex enum - withInt16")
    func parseComplexEnumWithInt16() throws {
        let data = Data([0x01, 0x12, 0x34])
        let parsed = try BenchmarkEnumComplex(parsing: data)
        let baseline = BenchmarkEnumComplex.parseBaseline(data)
        #expect(parsed == .withInt16(0x1234))
        #expect(parsed == baseline)
    }

    @Test("Parse complex enum - withUInt32")
    func parseComplexEnumWithUInt32() throws {
        let data = Data([0x02, 0x12, 0x34, 0x56, 0x78])
        let parsed = try BenchmarkEnumComplex(parsing: data)
        let baseline = BenchmarkEnumComplex.parseBaseline(data)
        #expect(parsed == .withUInt32(0x1234_5678))
        #expect(parsed == baseline)
    }

    @Test("Parse complex enum - withTwoValues")
    func parseComplexEnumWithTwoValues() throws {
        let data = Data([0x03, 0x12, 0x34, 0x56, 0x78])
        let parsed = try BenchmarkEnumComplex(parsing: data)
        let baseline = BenchmarkEnumComplex.parseBaseline(data)
        #expect(parsed == .withTwoValues(0x1234, 0x5678))
        #expect(parsed == baseline)
    }

    @Test("Parse complex enum - unknown (default)")
    func parseComplexEnumUnknown() throws {
        let data = Data([0xFF])
        let parsed = try BenchmarkEnumComplex(parsing: data)
        let baseline = BenchmarkEnumComplex.parseBaseline(data)
        #expect(parsed == .unknown)
        #expect(parsed == baseline)
    }

    // MARK: - Simple Struct Tests

    @Test("Parse simple struct")
    func parseSimpleStruct() throws {
        let data = Data([0x12, 0x34, 0x56, 0x78])
        let parsed = try BenchmarkStructSimple(parsing: data)
        let baseline = BenchmarkStructSimple.parseBaseline(data)
        #expect(parsed.value == 0x1234_5678)
        #expect(parsed == baseline)
    }

    // MARK: - Complex Struct Tests

    @Test("Parse complex struct")
    func parseComplexStruct() throws {
        let data = Data([
            0x89, 0x50, 0x4E, 0x47, // magic (BE)
            0x00, 0x00, // skip 2 bytes
            0x01, 0x00, // version (LE) = 1
            0x00, 0x00, 0x00, 0x00, 0x5F, 0x5E, 0x10, 0x00, // timestamp (BE)
            0x0F, 0x00, // flags (LE) = 15
        ])
        let parsed = try BenchmarkStructComplex(parsing: data)
        let baseline = BenchmarkStructComplex.parseBaseline(data)
        #expect(parsed.magic == 0x8950_4E47)
        #expect(parsed.version == 1)
        #expect(parsed.timestamp == 0x0000_0000_5F5E_1000)
        #expect(parsed.flags == 15)
        #expect(parsed == baseline)
    }

    // MARK: - Simple Bitmask Tests

    @Test("Parse simple bitmask")
    func parseSimpleBitmask() throws {
        let data = Data([0b1010_0011])
        try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            let parsed = try BenchmarkBitmaskSimple(bits: rawBits)
            let baseline = BenchmarkBitmaskSimple.parseBaseline(data)
            #expect(parsed.flag == 1)
            #expect(parsed.value == 0x23)
            #expect(parsed == baseline)
        }
    }

    // MARK: - Complex Bitmask Tests

    @Test("Parse complex bitmask")
    func parseComplexBitmask() throws {
        let data = Data([0xAB, 0xCD, 0xEF, 0x12])
        try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 32)
            let parsed = try BenchmarkBitmaskComplex(bits: rawBits)
            let baseline = BenchmarkBitmaskComplex.parseBaseline(data)
            #expect(parsed.flag1 == 1)
            #expect(parsed.priority == 2)
            #expect(parsed.nibble == 11)
            #expect(parsed.byte == 0xCD)
            #expect(parsed.word == 0xEF12)
            #expect(parsed == baseline)
        }
    }

    // MARK: - Endianness Tests

    @Test("Parse big endian struct")
    func parseBigEndianStruct() throws {
        let data = Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])
        let parsed = try BigEndianStruct(parsing: data)
        let baseline = BigEndianStruct.parseBaseline(data)
        #expect(parsed.value1 == 0x1234_5678)
        #expect(parsed.value2 == 0x9ABC_DEF0)
        #expect(parsed == baseline)
    }

    @Test("Parse little endian struct")
    func parseLittleEndianStruct() throws {
        let data = Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])
        let parsed = try LittleEndianStruct(parsing: data)
        let baseline = LittleEndianStruct.parseBaseline(data)
        #expect(parsed.value1 == 0x7856_3412)
        #expect(parsed.value2 == 0xF0DE_BC9A)
        #expect(parsed == baseline)
    }

    // MARK: - Non-Byte-Aligned Bitmask Tests

    @Test("Parse non-byte-aligned bitmask")
    func parseNonByteAlignedBitmask() throws {
        let data = Data([0xAC, 0xC0])
        try data.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 10)
            let parsed = try NonByteAlignedBitmask(bits: rawBits)
            let baseline = NonByteAlignedBitmask.parseBaseline(data)
            #expect(parsed.first == 5) // 101
            #expect(parsed.second == 12) // 01100
            #expect(parsed.third == 3) // 11
            #expect(parsed == baseline)
        }
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip simple struct")
    func roundTripSimpleStruct() throws {
        let original = BenchmarkStructSimple(value: 0x1234_5678)
        let printed = try original.printParsed(printer: .data)
        let reparsed = try BenchmarkStructSimple(parsing: printed)
        #expect(original == reparsed)
    }

    @Test("Round-trip simple bitmask")
    func roundTripSimpleBitmask() throws {
        let original = BenchmarkBitmaskSimple(flag: 1, value: 0x23)
        let printed = try original.printParsed(printer: .data)
        try printed.withParserSpan { parserSpan in
            let rawBits = RawBitsSpan(parserSpan.bytes, bitOffset: 0, bitCount: 8)
            let reparsed = try BenchmarkBitmaskSimple(bits: rawBits)
            #expect(original == reparsed)
        }
    }
}
