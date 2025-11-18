//
//  TestByteArrayPrinter.swift
//  BinaryParseKit
//
//  Created by Claude on 11/17/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite
struct ByteArrayPrinterTest {
    let printer = ByteArrayPrinter()

    // MARK: - Built-in Types Tests

    @Test
    func `print built-in type with big endian`() throws {
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03, 0x04], fixedEndianness: false),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: nil, endianness: .big, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result == [0x01, 0x02, 0x03, 0x04])
    }

    @Test
    func `print built-in type with little endian`() throws {
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03, 0x04], fixedEndianness: false),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: nil, endianness: .little, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result == [0x04, 0x03, 0x02, 0x01])
    }

    @Test
    func `print built-in type with fixed endianness ignores field endianness`() throws {
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03, 0x04], fixedEndianness: true),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: nil, endianness: .little, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result == [0x01, 0x02, 0x03, 0x04])
    }

    // MARK: - Struct Tests

    @Test
    func `print struct with multiple fields`() throws {
        let field1 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02])),
        )
        let field2 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .little,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x03, 0x04])),
        )
        let field3 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x05, 0x06])),
        )

        let structIntel = StructPrintIntel(fields: [field1, field2, field3])
        let result = try printer.print(.struct(structIntel))

        #expect(result == [0x01, 0x02, 0x04, 0x03, 0x05, 0x06])
    }

    @Test
    func `print struct with nested struct`() throws {
        let innerField = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0xAA, 0xBB])),
        )
        let innerStruct = PrinterIntel.struct(StructPrintIntel(fields: [innerField]))

        let outerField1 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02])),
        )
        let outerField2 = FieldPrinterIntel(byteCount: nil, endianness: nil, intel: innerStruct)

        let outerStruct = StructPrintIntel(fields: [outerField1, outerField2])
        let result = try printer.print(.struct(outerStruct))

        #expect(result == [0x01, 0x02, 0xAA, 0xBB])
    }

    // MARK: - Enum Tests

    @Test
    func `print enum with matchAndTake includes discriminator bytes`() throws {
        let enumIntel = EnumCasePrinterIntel(
            enumCaseName: "testCase",
            bytes: [0xFF, 0xFE],
            parseType: .matchAndTake,
            fields: [
                FieldPrinterIntel(
                    byteCount: nil,
                    endianness: .big,
                    intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02])),
                ),
            ],
        )

        let result = try printer.print(.enum(enumIntel))
        // Should include discriminator bytes [0xFF, 0xFE] followed by field bytes
        #expect(result == [0xFF, 0xFE, 0x01, 0x02])
    }

    @Test
    func `print enum with match does not include discriminator bytes`() throws {
        let enumIntel = EnumCasePrinterIntel(
            enumCaseName: "testCase",
            bytes: [0xFF, 0xFE],
            parseType: .match,
            fields: [
                FieldPrinterIntel(
                    byteCount: nil,
                    endianness: .big,
                    intel: .builtIn(BuiltInPrinterIntel(bytes: [0xFF, 0xFE])),
                ),
            ],
        )

        let result = try printer.print(.enum(enumIntel))
        // Should NOT include discriminator bytes
        #expect(result == [0xFF, 0xFE])
    }

    @Test
    func `print enum with matchDefault does not include discriminator bytes`() throws {
        let enumIntel = EnumCasePrinterIntel(
            enumCaseName: "defaultCase",
            bytes: [],
            parseType: .matchDefault,
            fields: [
                FieldPrinterIntel(
                    byteCount: nil,
                    endianness: .little,
                    intel: .builtIn(BuiltInPrinterIntel(bytes: [0x0A, 0x0B])),
                ),
            ],
        )

        let result = try printer.print(.enum(enumIntel))
        #expect(result == [0x0B, 0x0A])
    }

    // MARK: - Skip Tests

    @Test
    func `print skip creates zero-filled array`() throws {
        let skipIntel = SkipPrinterIntel(byteCount: 5)
        let result = try printer.print(.skip(skipIntel))

        #expect(result == [0x00, 0x00, 0x00, 0x00, 0x00])
    }

    @Test
    func `print struct with skip field`() throws {
        let field1 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02])),
        )
        let skipField = FieldPrinterIntel(
            byteCount: nil,
            endianness: nil,
            intel: .skip(SkipPrinterIntel(byteCount: 3)),
        )
        let field2 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x03, 0x04])),
        )

        let structIntel = StructPrintIntel(fields: [field1, skipField, field2])
        let result = try printer.print(.struct(structIntel))

        #expect(result == [0x01, 0x02, 0x00, 0x00, 0x00, 0x03, 0x04])
    }

    // MARK: - ByteCount Tests

    @Test
    func `byteCount limits output length`() throws {
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06]),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: 3, endianness: .big, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result == [0x04, 0x05, 0x06])
    }

    @Test
    func `byteCount with multiple fields truncates individual field`() throws {
        let field1 = FieldPrinterIntel(
            byteCount: 2,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03, 0x04])),
        )
        let field2 = FieldPrinterIntel(
            byteCount: nil,
            endianness: .big,
            intel: .builtIn(BuiltInPrinterIntel(bytes: [0x05, 0x06])),
        )

        let structIntel = StructPrintIntel(fields: [field1, field2])
        let result = try printer.print(.struct(structIntel))

        #expect(result == [0x03, 0x04, 0x05, 0x06])
    }

    @Test
    func `byteCount larger than available bytes uses all bytes`() throws {
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02]),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: 10, endianness: .big, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result == [0x01, 0x02])
    }

    @Test
    func `byteCount trims little endian built-in printer intel`() throws {
        // Big endian bytes [0x01, 0x02, 0x03, 0x04, 0x05, 0x06]
        // which is little endian [0x06, 0x05, 0x04, 0x03, 0x02, 0x01]
        // with byteCount 2 should give [0x06, 0x05]
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06]),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: 2, endianness: .little, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result == [0x06, 0x05])
    }

    // MARK: - Complex Integration Tests

    @Test
    func `complex struct with mixed endianness and skip`() throws {
        let fields: [FieldPrinterIntel] = [
            // Big endian field
            FieldPrinterIntel(
                byteCount: nil,
                endianness: .big,
                intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02])),
            ),
            // Skip 2 bytes
            FieldPrinterIntel(
                byteCount: nil,
                endianness: nil,
                intel: .skip(SkipPrinterIntel(byteCount: 2)),
            ),
            // Little endian field
            FieldPrinterIntel(
                byteCount: nil,
                endianness: .little,
                intel: .builtIn(BuiltInPrinterIntel(bytes: [0x03, 0x04])),
            ),
            // Limited byte count field
            FieldPrinterIntel(
                byteCount: 1,
                endianness: .big,
                intel: .builtIn(BuiltInPrinterIntel(bytes: [0x05, 0x06, 0x07])),
            ),
        ]

        let structIntel = StructPrintIntel(fields: fields)
        let result = try printer.print(.struct(structIntel))

        #expect(result == [0x01, 0x02, 0x00, 0x00, 0x04, 0x03, 0x07])
    }

    @Test
    func `enum with multiple fields and mixed endianness`() throws {
        let enumIntel = EnumCasePrinterIntel(
            enumCaseName: "complexCase",
            bytes: [0xAA, 0xBB],
            parseType: .matchAndTake,
            fields: [
                FieldPrinterIntel(
                    byteCount: nil,
                    endianness: .big,
                    intel: .builtIn(BuiltInPrinterIntel(bytes: [0x01, 0x02])),
                ),
                FieldPrinterIntel(
                    byteCount: nil,
                    endianness: .little,
                    intel: .builtIn(BuiltInPrinterIntel(bytes: [0x03, 0x04])),
                ),
            ],
        )

        let result = try printer.print(.enum(enumIntel))
        #expect(result == [0xAA, 0xBB, 0x01, 0x02, 0x04, 0x03])
    }

    @Test
    func `empty struct produces empty array`() throws {
        let structIntel = StructPrintIntel(fields: [])
        let result = try printer.print(.struct(structIntel))

        #expect(result.isEmpty)
    }

    @Test
    func `enum with no fields and matchAndTake only outputs discriminator`() throws {
        let enumIntel = EnumCasePrinterIntel(
            enumCaseName: "emptyCase",
            bytes: [0xFF],
            parseType: .matchAndTake,
            fields: [],
        )

        let result = try printer.print(.enum(enumIntel))
        #expect(result == [0xFF])
    }

    @Test
    func `byteCount zero returns empty array`() throws {
        let intel = PrinterIntel.builtIn(
            BuiltInPrinterIntel(bytes: [0x01, 0x02, 0x03]),
        )
        let fieldIntel = FieldPrinterIntel(byteCount: 0, endianness: .big, intel: intel)
        let structIntel = StructPrintIntel(fields: [fieldIntel])

        let result = try printer.print(.struct(structIntel))
        #expect(result.isEmpty)
    }
}
