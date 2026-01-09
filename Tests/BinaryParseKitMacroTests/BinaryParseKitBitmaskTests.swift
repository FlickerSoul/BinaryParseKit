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
    struct `Test Parsing Bitmask` { // swiftlint:disable:this type_body_length
        @Test
        func `successful expansion`() {
            assertMacro {
                """
                @ParseBitmask
                struct Flags {
                    @mask(bitCount: 1)
                    var flag1: Bool

                    @mask(bitCount: 3)
                    var value: UInt8

                    @mask
                    var flag2: Bool
                }
                """
            } expansion: {
                """
                struct Flags {
                    var flag1: Bool
                    var value: UInt8
                    var flag2: Bool
                }

                extension Flags: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        1 + 3 + (Bool).bitCount
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `flag1` of type `Bool` with specified bit count 1
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = 1
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.flag1 = try BinaryParseKit.__createFromBits(
                                (Bool).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                        // Parse `value` of type `UInt8` with specified bit count 3
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let __macro_local_10__bitCountfMu0_ = 3
                            let __macro_local_9__subSpanfMu0_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu0_)
                            self.value = try BinaryParseKit.__createFromBits(
                                (UInt8).self,
                                fieldBits: __macro_local_9__subSpanfMu0_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu0_,
                                bitEndian: .big,
                            )
                        }
                        // Parse `flag2` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        do {
                            let __macro_local_10__bitCountfMu1_ = (Bool).bitCount
                            let __macro_local_9__subSpanfMu1_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu1_)
                            self.flag2 = try BinaryParseKit.__createFromBits(
                                (Bool).self,
                                fieldBits: __macro_local_9__subSpanfMu1_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu1_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension Flags: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `flag1` of type `Bool` with specified bit count 1
                        result = result.appending(try BinaryParseKit.__toRawBits(self.flag1, bitCount: 1))
                        // Convert `value` of type `UInt8` with specified bit count 3
                        result = result.appending(try BinaryParseKit.__toRawBits(self.value, bitCount: 3))
                        // Convert `flag2` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertRawBitsConvertible((Bool).self)
                        result = result.appending(try BinaryParseKit.__toRawBits(self.flag2, bitCount: (Bool).bitCount))
                        return result
                    }
                }

                extension Flags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `class not supported`() {
            assertMacro {
                """
                @ParseBitmask
                class Flags {
                    @mask(bitCount: 1)
                    var flag: Bool
                }
                """
            } diagnostics: {
                """
                @ParseBitmask
                ┬────────────
                ╰─ 🛑 @ParseBitmask can only be applied to structs.
                class Flags {
                    @mask(bitCount: 1)
                    var flag: Bool
                }
                """
            }
        }

        @Test
        func `field without mask attribute`() {
            assertMacro {
                """
                @ParseBitmask
                struct Flags {
                    @mask(bitCount: 1)
                    var flag1: Bool

                    var flag2: Bool
                }
                """
            } diagnostics: {
                """
                @ParseBitmask
                ┬────────────
                ╰─ 🛑 Fatal error in ParseBitmask macro: Errors encountered while parsing @mask fields.
                struct Flags {
                    @mask(bitCount: 1)
                    var flag1: Bool

                    var flag2: Bool
                        ┬──────────
                        ╰─ 🛑 All fields in @ParseBitmask struct must have @mask attribute.
                }
                """
            }
        }

        @Test
        func `empty struct`() {
            assertMacro {
                """
                @ParseBitmask
                struct Flags {
                }
                """
            } diagnostics: {
                """
                @ParseBitmask
                ┬────────────
                ╰─ 🛑 @ParseBitmask struct must have at least one field with @mask attribute.
                struct Flags {
                }
                """
            }
        }

        @Test
        func `single field`() {
            assertMacro {
                """
                @ParseBitmask
                struct SingleFlag {
                    @mask(bitCount: 1)
                    var flag: Bool
                }
                """
            } expansion: {
                """
                struct SingleFlag {
                    var flag: Bool
                }

                extension SingleFlag: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        1
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `flag` of type `Bool` with specified bit count 1
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = 1
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.flag = try BinaryParseKit.__createFromBits(
                                (Bool).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension SingleFlag: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `flag` of type `Bool` with specified bit count 1
                        result = result.appending(try BinaryParseKit.__toRawBits(self.flag, bitCount: 1))
                        return result
                    }
                }

                extension SingleFlag: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `ignores computed properties`() {
            assertMacro {
                """
                @ParseBitmask
                struct Flags {
                    @mask(bitCount: 4)
                    var value: UInt8

                    var computedValue: Int {
                        Int(value) * 2
                    }
                }
                """
            } expansion: {
                """
                struct Flags {
                    var value: UInt8

                    var computedValue: Int {
                        Int(value) * 2
                    }
                }

                extension Flags: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        4
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `value` of type `UInt8` with specified bit count 4
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = 4
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.value = try BinaryParseKit.__createFromBits(
                                (UInt8).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension Flags: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `value` of type `UInt8` with specified bit count 4
                        result = result.appending(try BinaryParseKit.__toRawBits(self.value, bitCount: 4))
                        return result
                    }
                }

                extension Flags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `ignores computed properties with getter and setter`() {
            assertMacro {
                """
                @ParseBitmask
                struct Flags {
                    @mask(bitCount: 8)
                    var rawValue: UInt8

                    var isEnabled: Bool {
                        get { rawValue & 0x01 != 0 }
                        set { rawValue = newValue ? (rawValue | 0x01) : (rawValue & 0xFE) }
                    }
                }
                """
            } expansion: {
                """
                struct Flags {
                    var rawValue: UInt8

                    var isEnabled: Bool {
                        get { rawValue & 0x01 != 0 }
                        set { rawValue = newValue ? (rawValue | 0x01) : (rawValue & 0xFE) }
                    }
                }

                extension Flags: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        8
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `rawValue` of type `UInt8` with specified bit count 8
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = 8
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.rawValue = try BinaryParseKit.__createFromBits(
                                (UInt8).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension Flags: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `rawValue` of type `UInt8` with specified bit count 8
                        result = result.appending(try BinaryParseKit.__toRawBits(self.rawValue, bitCount: 8))
                        return result
                    }
                }

                extension Flags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `ignores static properties`() {
            assertMacro {
                """
                @ParseBitmask
                struct Flags {
                    static let defaultValue: UInt8 = 0

                    @mask(bitCount: 8)
                    var value: UInt8
                }
                """
            } expansion: {
                """
                struct Flags {
                    static let defaultValue: UInt8 = 0
                    var value: UInt8
                }

                extension Flags: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        8
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `value` of type `UInt8` with specified bit count 8
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = 8
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.value = try BinaryParseKit.__createFromBits(
                                (UInt8).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension Flags: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `value` of type `UInt8` with specified bit count 8
                        result = result.appending(try BinaryParseKit.__toRawBits(self.value, bitCount: 8))
                        return result
                    }
                }

                extension Flags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `all inferred bitCounts`() {
            assertMacro {
                """
                @ParseBitmask
                struct InferredFlags {
                    @mask
                    var flag1: Bool

                    @mask
                    var flag2: Bool
                }
                """
            } expansion: {
                """
                struct InferredFlags {
                    var flag1: Bool
                    var flag2: Bool
                }

                extension InferredFlags: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        (Bool).bitCount + (Bool).bitCount
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `flag1` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = (Bool).bitCount
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.flag1 = try BinaryParseKit.__createFromBits(
                                (Bool).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                        // Parse `flag2` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        do {
                            let __macro_local_10__bitCountfMu0_ = (Bool).bitCount
                            let __macro_local_9__subSpanfMu0_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu0_)
                            self.flag2 = try BinaryParseKit.__createFromBits(
                                (Bool).self,
                                fieldBits: __macro_local_9__subSpanfMu0_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu0_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension InferredFlags: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `flag1` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertRawBitsConvertible((Bool).self)
                        result = result.appending(try BinaryParseKit.__toRawBits(self.flag1, bitCount: (Bool).bitCount))
                        // Convert `flag2` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertRawBitsConvertible((Bool).self)
                        result = result.appending(try BinaryParseKit.__toRawBits(self.flag2, bitCount: (Bool).bitCount))
                        return result
                    }
                }

                extension InferredFlags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `custom accessors`() {
            assertMacro {
                """
                @ParseBitmask(parsingAccessor: .public, printingAccessor: .public)
                struct PublicFlags {
                    @mask(bitCount: 1)
                    var flag: Bool
                }
                """
            } expansion: {
                """
                struct PublicFlags {
                    var flag: Bool
                }

                extension PublicFlags: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    public static var bitCount: Int {
                        1
                    }
                    public init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `flag` of type `Bool` with specified bit count 1
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = 1
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.flag = try BinaryParseKit.__createFromBits(
                                (Bool).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension PublicFlags: BinaryParseKit.RawBitsConvertible {
                    public func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `flag` of type `Bool` with specified bit count 1
                        result = result.appending(try BinaryParseKit.__toRawBits(self.flag, bitCount: 1))
                        return result
                    }
                }

                extension PublicFlags: BinaryParseKit.Printable {
                    public func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }

        @Test
        func `no type annotation`() {
            assertMacro {
                """
                @ParseBitmask(parsingAccessor: .public, printingAccessor: .public)
                struct PublicFlags {
                    @mask(bitCount: 1)
                    var flag
                }
                """
            } diagnostics: {
                """
                @ParseBitmask(parsingAccessor: .public, printingAccessor: .public)
                ┬─────────────────────────────────────────────────────────────────
                ╰─ 🛑 Fatal error in ParseBitmask macro: Errors encountered while parsing @mask fields.
                struct PublicFlags {
                    @mask(bitCount: 1)
                    var flag
                        ┬───
                        ╰─ 🛑 @mask fields must have a type annotation.
                }
                """
            }
        }

        @Test
        func `negative mask bit count`() {
            assertMacro {
                """
                @ParseBitmask
                struct PublicFlags {
                    @mask(bitCount: -1)
                    var flag: Int
                }
                """
            } diagnostics: {
                """
                @ParseBitmask
                ┬────────────
                ╰─ 🛑 Fatal error in ParseBitmask macro: Errors encountered while parsing @mask fields.
                struct PublicFlags {
                    @mask(bitCount: -1)
                    ┬──────────────────
                    ╰─ 🛑 The bitCount argument must be a positive integer.
                    var flag: Int
                }
                """
            }
        }

        @Test
        func `zero mask bit count`() {
            assertMacro {
                """
                @ParseBitmask
                struct PublicFlags {
                    @mask(bitCount: 0)
                    var flag: Int
                }
                """
            } diagnostics: {
                """
                @ParseBitmask
                ┬────────────
                ╰─ 🛑 Fatal error in ParseBitmask macro: Errors encountered while parsing @mask fields.
                struct PublicFlags {
                    @mask(bitCount: 0)
                    ┬─────────────────
                    ╰─ 🛑 The bitCount argument must be a positive integer.
                    var flag: Int
                }
                """
            }
        }

        @Test
        func `complex structure test`() {
            assertMacro {
                """
                @ParseBitmask
                struct ComplexTest {
                    @mask
                    let a: Flag

                    var b: Flag {
                        get {
                            a
                        }
                        set {
                            a = newValue
                        }
                    }

                    func a() -> Flag {
                        let value = 1
                        return b
                    }

                    static func b() -> Flag {
                        var value = Flag()
                        value.change()
                        return value
                    }

                    struct Flag {
                        let value: Int
                    }

                    enum EnumFlag {
                        case flag
                    }

                    class ClassFlag {
                        @Observed
                        var value: Int = 1
                    }

                    actor ActorFlag {
                        var value = 1
                    }
                }
                """
            } expansion: {
                """
                struct ComplexTest {
                    let a: Flag

                    var b: Flag {
                        get {
                            a
                        }
                        set {
                            a = newValue
                        }
                    }

                    func a() -> Flag {
                        let value = 1
                        return b
                    }

                    static func b() -> Flag {
                        var value = Flag()
                        value.change()
                        return value
                    }

                    struct Flag {
                        let value: Int
                    }

                    enum EnumFlag {
                        case flag
                    }

                    class ClassFlag {
                        @Observed
                        var value: Int = 1
                    }

                    actor ActorFlag {
                        var value = 1
                    }
                }

                extension ComplexTest: BinaryParseKit.ExpressibleByRawBits, BinaryParseKit.BitCountProviding {
                    internal static var bitCount: Int {
                        (Flag).bitCount
                    }
                    internal init(bits: borrowing BinaryParseKit.RawBitsSpan) throws {
                        var __macro_local_10__bitsSpanfMu_ = RawBitsSpan(copying: bits)
                        // Parse `a` of type `Flag` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Flag).self)
                        do {
                            let __macro_local_10__bitCountfMu_ = (Flag).bitCount
                            let __macro_local_9__subSpanfMu_ = __macro_local_10__bitsSpanfMu_.slicing(unchecked: (), first: __macro_local_10__bitCountfMu_)
                            self.a = try BinaryParseKit.__createFromBits(
                                (Flag).self,
                                fieldBits: __macro_local_9__subSpanfMu_,
                                fieldRequestedBitCount: __macro_local_10__bitCountfMu_,
                                bitEndian: .big,
                            )
                        }
                    }
                }

                extension ComplexTest: BinaryParseKit.RawBitsConvertible {
                    internal func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits {
                        var result = BinaryParseKit.RawBits()
                        // Convert `a` of type `Flag` with inferred bit count
                        BinaryParseKit.__assertRawBitsConvertible((Flag).self)
                        result = result.appending(try BinaryParseKit.__toRawBits(self.a, bitCount: (Flag).bitCount))
                        return result
                    }
                }

                extension ComplexTest: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        let bits = try self.toRawBits(bitCount: Self.bitCount)
                        return .bitmask(.init(bits: bits))
                    }
                }
                """
            }
        }
    }
}
