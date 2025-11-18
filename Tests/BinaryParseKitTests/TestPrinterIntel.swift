//
//  TestPrinterIntel.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite
struct PrinterIntelTest {
    // MARK: - ParseEnum PrinterIntel Tests

    @ParseEnum
    enum BasicEnum {
        @match(byte: 0x01)
        case first

        @match(bytes: [0x02, 0x03])
        case second

        @match(byte: 0x04)
        case third
    }

    @Test
    func `basic enum printerIntel generation`() throws {
        let firstIntel = try BasicEnum.first.printerIntel()
        let enumIntel = try #require(firstIntel.enumIntel)

        #expect(enumIntel.enumCaseName == "first")
        #expect(enumIntel.bytes == [0x01])
        #expect(enumIntel.parseType == .match)
        #expect(enumIntel.fields.isEmpty)

        let secondIntel = try BasicEnum.second.printerIntel()
        let enumIntel2 = try #require(secondIntel.enumIntel)

        #expect(enumIntel2.enumCaseName == "second")
        #expect(enumIntel2.bytes == [0x02, 0x03])
        #expect(enumIntel2.parseType == .match)
        #expect(enumIntel2.fields.isEmpty)
    }

    @ParseEnum
    enum EnumWithAssociatedValuesBE: Equatable {
        @match(byte: 0x01)
        @parse(endianness: .big)
        case withInt16(Int16)

        @match(byte: 0x02)
        @parse(endianness: .big)
        @parse(endianness: .big)
        case withTwoValues(Int16, UInt16)
    }

    @Test
    func `enum with associated values printerIntel (match)`() throws {
        let value = EnumWithAssociatedValuesBE.withInt16(0x1234)
        let intel = try value.printerIntel()
        let enumIntel = try #require(intel.enumIntel)

        #expect(enumIntel.enumCaseName == "withInt16")
        #expect(enumIntel.bytes == [0x01])
        #expect(enumIntel.parseType == .match)
        #expect(enumIntel.fields.count == 1)

        let field = enumIntel.fields[0]
        #expect(field.endianness == .big)
        #expect(field.byteCount == nil)

        let builtIn = try #require(field.intel.builtInIntel)
        #expect(builtIn.bytes == [0x12, 0x34])
    }

    @ParseEnum
    enum EnumWithMatchAndTakeBE: Equatable {
        @matchAndTake(byte: 0x01)
        @parse(endianness: .big)
        case withValue(UInt16)

        @matchAndTake(bytes: [0x02, 0x03])
        @parse(endianness: .big)
        @parse(endianness: .big)
        case withTwoValues(Int16, UInt16)
    }

    @Test
    func `enum with matchAndTake printerIntel`() throws {
        let value = EnumWithMatchAndTakeBE.withValue(0x5678)
        let intel = try value.printerIntel()
        let enumIntel = try #require(intel.enumIntel)

        #expect(enumIntel.enumCaseName == "withValue")
        #expect(enumIntel.bytes == [0x01])
        #expect(enumIntel.parseType == .matchAndTake)
        #expect(enumIntel.fields.count == 1)

        let twoValues = EnumWithMatchAndTakeBE.withTwoValues(0x1234, 0x5678)
        let intel2 = try twoValues.printerIntel()
        let enumIntel2 = try #require(intel2.enumIntel)

        #expect(enumIntel2.enumCaseName == "withTwoValues")
        #expect(enumIntel2.bytes == [0x02, 0x03])
        #expect(enumIntel2.parseType == .matchAndTake)
        #expect(enumIntel2.fields.count == 2)
    }

    @ParseEnum
    enum EnumWithDefaultCase {
        @match(byte: 0x01)
        case known

        @matchDefault
        case unknown
    }

    @Test
    func `enum with default case printerIntel`() throws {
        let knownIntel = try EnumWithDefaultCase.known.printerIntel()
        let knownEnum = try #require(knownIntel.enumIntel)
        #expect(knownEnum.parseType == .match)
        #expect(knownEnum.bytes == [0x01])

        let unknownIntel = try EnumWithDefaultCase.unknown.printerIntel()
        let unknownEnum = try #require(unknownIntel.enumIntel)
        #expect(unknownEnum.parseType == .matchDefault)
        #expect(unknownEnum.bytes.isEmpty)
    }

    @ParseEnum
    enum EnumWithSkipBE: Equatable {
        @matchAndTake(byte: 0x01)
        @skip(byteCount: 2, because: "padding")
        @parse(endianness: .big)
        case withSkip(Int16)

        @matchAndTake(byte: 0x02)
        @parse(endianness: .big)
        @skip(byteCount: 1, because: "reserved")
        @parse(endianness: .big)
        case withMiddleSkip(UInt8, UInt16)
    }

    @Test
    func `enum with skip printerIntel`() throws {
        let value = EnumWithSkipBE.withSkip(0x1234)
        let intel = try value.printerIntel()
        let enumIntel = try #require(intel.enumIntel)

        #expect(enumIntel.fields.count == 2)

        // First field should be skip
        let skipIntel = try #require(enumIntel.fields[0].intel.skipIntel)
        #expect(skipIntel.byteCount == 2)

        // Second field should be the actual value
        _ = try #require(enumIntel.fields[1].intel.builtInIntel)
    }

    // MARK: - ParseStruct PrinterIntel Tests

    @ParseStruct
    struct BasicStructBE {
        @parse(byteCount: 2, endianness: .big)
        let first: Int16

        @parse(byteCount: 2, endianness: .big)
        let second: Int16
    }

    @Test
    func `basic struct printerIntel generation`() throws {
        let value = try BasicStructBE(parsing: [0x01, 0x02, 0x03, 0x04])
        let intel = try value.printerIntel()
        let structIntel = try #require(intel.structIntel)

        #expect(structIntel.fields.count == 2)

        // First field
        let field1 = structIntel.fields[0]
        #expect(field1.byteCount == 2)
        #expect(field1.endianness == .big)
        let builtIn1 = try #require(field1.intel.builtInIntel)
        #expect(builtIn1.bytes == [0x01, 0x02])

        // Second field
        let field2 = structIntel.fields[1]
        #expect(field2.byteCount == 2)
        #expect(field2.endianness == .big)
        let builtIn2 = try #require(field2.intel.builtInIntel)
        #expect(builtIn2.bytes == [0x03, 0x04])
    }

    @ParseStruct
    struct MixedEndianStruct {
        @parse(byteCount: 2, endianness: .big)
        let bigEndian: Int16

        @parse(byteCount: 2, endianness: .little)
        let littleEndian: Int16
    }

    @Test
    func `struct with mixed endianness printerIntel`() throws {
        let value = try MixedEndianStruct(parsing: [0x01, 0x02, 0x03, 0x04])
        let intel = try value.printerIntel()
        let structIntel = try #require(intel.structIntel)

        #expect(structIntel.fields.count == 2)

        let field1 = structIntel.fields[0]
        #expect(field1.endianness == .big)

        let field2 = structIntel.fields[1]
        #expect(field2.endianness == .little)
    }

    @ParseStruct
    struct StructWithSkipBE {
        @skip(byteCount: 2, because: "padding")
        @parse(byteCount: 2, endianness: .big)
        let value: Int16

        @parse(byteCount: 1, endianness: .big)
        let byte: Int8

        @skip(byteCount: 3, because: "more padding")
        @parse(endianness: .big)
        let footer: UInt16
    }

    @Test
    func `struct with skip printerIntel`() throws {
        let value = try StructWithSkipBE(parsing: [0xFF, 0xFF, 0x01, 0x02, 0x42, 0xAA, 0xBB, 0xCC, 0x12, 0x34])
        let intel = try value.printerIntel()
        let structIntel = try #require(intel.structIntel)

        // Should have 3 fields: (skip+value), byte, (skip+footer)
        #expect(structIntel.fields.count == 5)

        // First field (value)
        let field1 = structIntel.fields[1]
        #expect(field1.byteCount == 2)
        #expect(field1.endianness == .big)
        let builtIn1 = try #require(field1.intel.builtInIntel)
        #expect(builtIn1.bytes == [0x01, 0x02])

        // Second field (byte)
        let field2 = structIntel.fields[2]
        #expect(field2.byteCount == 1)
        #expect(field2.endianness == .big)
        let builtIn2 = try #require(field2.intel.builtInIntel)
        #expect(builtIn2.bytes == [0x42])

        // Third field (footer)
        let field3 = structIntel.fields[4]
        #expect(field3.endianness == .big)
        let builtIn3 = try #require(field3.intel.builtInIntel)
        #expect(builtIn3.bytes == [0x12, 0x34])
    }

    @Test
    func `struct with skip round-trip`() throws {
        let originalData: [UInt8] = [0xAA, 0xBB, 0x01, 0x02, 0x42, 0xCC, 0xDD, 0xEE, 0x12, 0x34]
        let parsed = try StructWithSkipBE(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .byteArray)

        // Skip bytes should be printed as zeros
        let expectedData: [UInt8] = [0x00, 0x00, 0x01, 0x02, 0x42, 0x00, 0x00, 0x00, 0x12, 0x34]
        #expect(printedBytes == expectedData)
    }

    // MARK: - Round-trip Tests (Parse -> PrinterIntel -> Print -> Parse)

    @Test
    func `enum round-trip with printer`() throws {
        let originalData: [UInt8] = [0x01, 0x12, 0x34]
        let parsed = try EnumWithMatchAndTakeBE(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .byteArray)

        // Should match original data
        #expect(printedBytes == originalData)

        // Parse again to verify
        let reparsed = try EnumWithMatchAndTakeBE(parsing: printedBytes)
        #expect(reparsed == parsed)
    }

    @Test
    func `struct round-trip with printer`() throws {
        let originalData: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        let parsed = try BasicStructBE(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .byteArray)

        // Should match original data
        #expect(printedBytes == originalData)

        // Parse again to verify
        let reparsed = try BasicStructBE(parsing: printedBytes)
        #expect(reparsed.first == parsed.first)
        #expect(reparsed.second == parsed.second)
    }

    @Test
    func `enum with skip round-trip`() throws {
        let originalData: [UInt8] = [0x01, 0xFF, 0xFF, 0x12, 0x34]
        let parsed = try EnumWithSkipBE(parsing: originalData)

        let printedBytes = try parsed.printParsed(printer: .byteArray)

        // Skip bytes should be printed as zeros
        let expectedData: [UInt8] = [0x01, 0x00, 0x00, 0x12, 0x34]
        #expect(printedBytes == expectedData)
    }

    @ParseEnum
    enum ComplexEnum: Equatable {
        @match(byte: 0x01)
        case simple

        @matchAndTake(bytes: [0x02, 0x03])
        @skip(byteCount: 2, because: "reserved")
        @parse(endianness: .big)
        case withSkip(UInt16)

        @matchAndTake(byte: 0x04)
        @parse(endianness: .big)
        @parse(endianness: .little)
        case complex(Int16, UInt16)
    }

    @Test
    func `complex enum round-trip`() throws {
        // Test simple case
        let simpleData: [UInt8] = [0x01]
        let simpleParsed = try ComplexEnum(parsing: simpleData)
        let simplePrinted = try simpleParsed.printParsed(printer: .byteArray)
        // Empty because `match` does not consume any bytes
        // and are not included in print output
        let expectedSimpleData: [UInt8] = []
        #expect(simplePrinted == expectedSimpleData)

        // Test withSkip case
        let skipData: [UInt8] = [0x02, 0x03, 0xFF, 0xFF, 0x12, 0x34]
        let skipParsed = try ComplexEnum(parsing: skipData)
        let skipPrinted = try skipParsed.printParsed(printer: .byteArray)
        let expectedSkipData: [UInt8] = [0x02, 0x03, 0x00, 0x00, 0x12, 0x34]
        #expect(skipPrinted == expectedSkipData)

        // Test complex case
        let complexData: [UInt8] = [0x04, 0x12, 0x34, 0x78, 0x56]
        let complexParsed = try ComplexEnum(parsing: complexData)
        let complexPrinted = try complexParsed.printParsed(printer: .byteArray)
        #expect(complexPrinted == complexData)
    }

    @ParseStruct
    struct AllTypesStructBE {
        @parse(endianness: .big)
        let int8: Int8

        @parse(endianness: .big)
        let uint8: UInt8

        @parse(endianness: .big)
        let int16: Int16

        @parse(endianness: .big)
        let uint16: UInt16

        @parse(endianness: .big)
        let int32: Int32

        @parse(endianness: .big)
        let uint32: UInt32
    }

    @Test
    func `struct with all basic types round-trip`() throws {
        let originalData: [UInt8] = [
            0x01, // int8
            0x02, // uint8
            0x03, 0x04, // int16
            0x05, 0x06, // uint16
            0x07, 0x08, 0x09, 0x0A, // int32
            0x0B, 0x0C, 0x0D, 0x0E, // uint32
        ]

        let parsed = try AllTypesStructBE(parsing: originalData)
        let printed = try parsed.printParsed(printer: .byteArray)

        #expect(printed == originalData)

        // Verify values
        let reparsed = try AllTypesStructBE(parsing: printed)
        #expect(reparsed.int8 == 0x01)
        #expect(reparsed.uint8 == 0x02)
        #expect(reparsed.int16 == 0x0304)
        #expect(reparsed.uint16 == 0x0506)
        #expect(reparsed.int32 == 0x0708_090A)
        #expect(reparsed.uint32 == 0x0B0C_0D0E)
    }
}

// MARK: - Test Convenience Extensions

extension PrinterIntel {
    var structIntel: StructPrintIntel? {
        if case let .struct(intel) = self {
            return intel
        }
        return nil
    }

    var enumIntel: EnumCasePrinterIntel? {
        if case let .enum(intel) = self {
            return intel
        }
        return nil
    }

    var builtInIntel: BuiltInPrinterIntel? {
        if case let .builtIn(intel) = self {
            return intel
        }
        return nil
    }

    var skipIntel: SkipPrinterIntel? {
        if case let .skip(intel) = self {
            return intel
        }
        return nil
    }
}
