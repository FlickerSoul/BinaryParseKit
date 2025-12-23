//
//  BinaryParseKitBitmaskTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/23/25.
//

import BinaryParseKitCommons
@testable import BinaryParseKitMacros
import MacroTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

extension BinaryParseKitMacroTests {
    @Suite
    struct TestParsingBitmask {
        // MARK: - Basic Struct Bitmask Tests

        @Test
        func `basic struct bitmask expansion`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 8)
                struct Flags {
                    @mask(bitCount: 4) let high: UInt8
                    @mask(bitCount: 4) let low: UInt8
                }
                """#
            } expansion: {
                """
                struct Flags {
                    let high: UInt8
                    let low: UInt8
                }

                extension Flags: BinaryParseKit.BitmaskParsable {
                    typealias RawValue = UInt8
                    internal static var bitCount: Int {
                        8
                    }
                    internal static var endianness: Endianness? {
                        nil
                    }
                    internal static var bitOrder: BinaryParseKit.BitOrder {
                        BinaryParseKit.BitOrder.msbFirst
                    }
                    internal init(bitmask rawValue: RawValue) throws(BitmaskParsableError) {
                        // Extract `high` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.high = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 0,
                                bitCount: 4,
                                totalBitCount: 8,
                                bitOrder: Self.bitOrder
                            )
                        )
                        // Extract `low` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.low = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 4,
                                bitCount: 4,
                                totalBitCount: 8,
                                bitOrder: Self.bitOrder
                            )
                        )
                    }
                }

                extension Flags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: 4, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(high)), .init(byteCount: 4, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(low))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func `struct bitmask with lsb first expansion`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 8, bitOrder: .lsbFirst)
                struct LsbFlags {
                    @mask(bitCount: 2) let first: UInt8
                    @mask(bitCount: 6) let second: UInt8
                }
                """#
            } expansion: {
                """
                struct LsbFlags {
                    let first: UInt8
                    let second: UInt8
                }

                extension LsbFlags: BinaryParseKit.BitmaskParsable {
                    typealias RawValue = UInt8
                    internal static var bitCount: Int {
                        8
                    }
                    internal static var endianness: Endianness? {
                        nil
                    }
                    internal static var bitOrder: BinaryParseKit.BitOrder {
                        BinaryParseKit.BitOrder.lsbFirst
                    }
                    internal init(bitmask rawValue: RawValue) throws(BitmaskParsableError) {
                        // Extract `first` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.first = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 0,
                                bitCount: 2,
                                totalBitCount: 8,
                                bitOrder: Self.bitOrder
                            )
                        )
                        // Extract `second` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.second = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 2,
                                bitCount: 6,
                                totalBitCount: 8,
                                bitOrder: Self.bitOrder
                            )
                        )
                    }
                }

                extension LsbFlags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: 2, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(first)), .init(byteCount: 6, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(second))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func `multi byte bitmask with endianness expansion`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 16, endianness: .big)
                struct Header {
                    @mask(bitCount: 4) let version: UInt8
                    @mask(bitCount: 12) let length: UInt16
                }
                """#
            } expansion: {
                """
                struct Header {
                    let version: UInt8
                    let length: UInt16
                }

                extension Header: BinaryParseKit.BitmaskParsable {
                    typealias RawValue = UInt16
                    internal static var bitCount: Int {
                        16
                    }
                    internal static var endianness: Endianness? {
                        .big
                    }
                    internal static var bitOrder: BinaryParseKit.BitOrder {
                        BinaryParseKit.BitOrder.msbFirst
                    }
                    internal init(bitmask rawValue: RawValue) throws(BitmaskParsableError) {
                        // Extract `version` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.version = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 0,
                                bitCount: 4,
                                totalBitCount: 16,
                                bitOrder: Self.bitOrder
                            )
                        )
                        // Extract `length` of type UInt16
                        BinaryParseKit.__assertExpressibleByBitmask((UInt16).self)
                        self.length = try UInt16(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 4,
                                bitCount: 12,
                                totalBitCount: 16,
                                bitOrder: Self.bitOrder
                            )
                        )
                    }
                }

                extension Header: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: 4, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(version)), .init(byteCount: 12, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(length))]
                            )
                        )
                    }
                }
                """
            }
        }

        // MARK: - Enum Bitmask Tests

        @Test
        func `basic enum bitmask expansion`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 2)
                enum Direction: UInt8 {
                    case north = 0b00
                    case east  = 0b01
                    case south = 0b10
                    case west  = 0b11
                }
                """#
            } expansion: {
                """
                enum Direction: UInt8 {
                    case north = 0b00
                    case east  = 0b01
                    case south = 0b10
                    case west  = 0b11
                }

                private struct __Bitmask_Direction: BinaryParseKit.BitmaskParsable {
                    typealias RawValue = UInt8

                    let rawValue: RawValue

                    static var bitCount: Int {
                        2
                    }
                    static var endianness: Endianness? {
                        nil
                    }
                    static var bitOrder: BinaryParseKit.BitOrder {
                        BinaryParseKit.BitOrder.msbFirst
                    }

                    init(bitmask rawValue: RawValue) throws(BinaryParsing.ThrownParsingError) {
                        self.rawValue = rawValue
                    }
                }

                extension Direction: BinaryParseKit.Parsable {
                    public init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        let shim = try __Bitmask_Direction(parsing: &span)
                        switch shim.rawValue {
                        case 0b00:
                            self = .north
                        case 0b01:
                            self = .east
                        case 0b10:
                            self = .south
                        case 0b11:
                            self = .west
                        default:
                            throw BinaryParsing.ThrownParsingError(BitmaskParsableError.invalidEnumRawValue)
                        }
                    }
                }
                """
            }
        }

        // MARK: - Error Case Tests

        @Test
        func `missing endianness for multi byte error`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 16)
                struct BadHeader {
                    @mask(bitCount: 4) let version: UInt8
                    @mask(bitCount: 12) let length: UInt16
                }
                """#
            } diagnostics: {
                """
                @ParseBitmask(bitCount: 16)
                ┬──────────────────────────
                ╰─ 🛑 Bitmask with 16 bits (more than 8) requires endianness to be specified.
                struct BadHeader {
                    @mask(bitCount: 4) let version: UInt8
                    @mask(bitCount: 12) let length: UInt16
                }
                """
            }
        }

        @Test
        func `bit count mismatch error`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 8)
                struct BadFlags {
                    @mask(bitCount: 4) let high: UInt8
                    @mask(bitCount: 2) let low: UInt8
                }
                """#
            } diagnostics: {
                """
                @ParseBitmask(bitCount: 8)
                ┬─────────────────────────
                ╰─ 🛑 Bit count mismatch: specified 8 bits but fields total 6 bits.
                struct BadFlags {
                    @mask(bitCount: 4) let high: UInt8
                    @mask(bitCount: 2) let low: UInt8
                }
                """
            }
        }

        @Test
        func `missing mask attribute error`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 8)
                struct BadFlags {
                    @mask(bitCount: 4) let high: UInt8
                    let low: UInt8
                }
                """#
            } diagnostics: {
                """
                @ParseBitmask(bitCount: 8)
                ┬─────────────────────────
                ╰─ 🛑 Fatal error: Encountered errors while collecting @mask fields.
                struct BadFlags {
                    @mask(bitCount: 4) let high: UInt8
                    let low: UInt8
                    ┬─────────────
                    ╰─ 🛑 Stored property 'low' must have a @mask attribute.
                }
                """
            }
        }

        @Test
        func `enum with associated values error`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 2)
                enum BadDirection: UInt8 {
                    case north(Int) = 0b00
                    case south = 0b10
                }
                """#
            } diagnostics: {
                """
                @ParseBitmask(bitCount: 2)
                ┬─────────────────────────
                ├─ 🛑 @ParseBitmask cannot be applied to enums with associated values.
                ╰─ 🛑 @ParseBitmask cannot be applied to enums with associated values.
                enum BadDirection: UInt8 {
                    case north(Int) = 0b00
                    case south = 0b10
                }
                """
            }
        }

        @Test
        func `enum without raw values error`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 2)
                enum BadDirection {
                    case north
                    case south
                }
                """#
            } diagnostics: {
                """
                @ParseBitmask(bitCount: 2)
                ┬─────────────────────────
                ├─ 🛑 @ParseBitmask requires enums to have a raw value type conforming to BinaryInteger.
                ╰─ 🛑 @ParseBitmask requires enums to have a raw value type conforming to BinaryInteger.
                enum BadDirection {
                    case north
                    case south
                }
                """
            }
        }

        @Test
        func `unsupported declaration type error`() {
            assertMacro {
                #"""
                @ParseBitmask(bitCount: 8)
                class BadClass {
                    @mask(bitCount: 8) var value: UInt8 = 0
                }
                """#
            } diagnostics: {
                """
                @ParseBitmask(bitCount: 8)
                ┬─────────────────────────
                ╰─ 🛑 @ParseBitmask can only be applied to structs or enums.
                class BadClass {
                    @mask(bitCount: 8) var value: UInt8 = 0
                }
                """
            }
        }

        // MARK: - Inferred Bit Count Tests

        @Test
        func `inferred bit count expansion`() {
            assertMacro {
                #"""
                @ParseBitmask
                struct InferredFlags {
                    @mask(bitCount: 4) let high: UInt8
                    @mask(bitCount: 4) let low: UInt8
                }
                """#
            } expansion: {
                """
                struct InferredFlags {
                    let high: UInt8
                    let low: UInt8
                }

                extension InferredFlags: BinaryParseKit.BitmaskParsable {
                    typealias RawValue = UInt8
                    internal static var bitCount: Int {
                        8
                    }
                    internal static var endianness: Endianness? {
                        nil
                    }
                    internal static var bitOrder: BinaryParseKit.BitOrder {
                        BinaryParseKit.BitOrder.msbFirst
                    }
                    internal init(bitmask rawValue: RawValue) throws(BitmaskParsableError) {
                        // Extract `high` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.high = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 0,
                                bitCount: 4,
                                totalBitCount: 8,
                                bitOrder: Self.bitOrder
                            )
                        )
                        // Extract `low` of type UInt8
                        BinaryParseKit.__assertExpressibleByBitmask((UInt8).self)
                        self.low = try UInt8(
                            bitmask: BinaryParseKit.__extractBits(
                                from: rawValue,
                                startBit: 4,
                                bitCount: 4,
                                totalBitCount: 8,
                                bitOrder: Self.bitOrder
                            )
                        )
                    }
                }

                extension InferredFlags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: 4, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(high)), .init(byteCount: 4, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(low))]
                            )
                        )
                    }
                }
                """
            }
        }
    }
}
