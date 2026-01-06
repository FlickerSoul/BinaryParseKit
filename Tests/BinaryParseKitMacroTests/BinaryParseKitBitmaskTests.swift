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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `flag1` of type `Bool` with specified bit count 1
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        do {
                            let fieldBitCount = 1
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Bool).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.flag1 = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
                        }
                        // Parse `value` of type `UInt8` with specified bit count 3
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let fieldBitCount = 3
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (UInt8).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.value = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
                        }
                        // Parse `flag2` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        do {
                            let fieldBitCount = (Bool).bitCount
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Bool).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.flag2 = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `flag` of type `Bool` with specified bit count 1
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        do {
                            let fieldBitCount = 1
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Bool).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.flag = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `value` of type `UInt8` with specified bit count 4
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let fieldBitCount = 4
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (UInt8).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.value = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `rawValue` of type `UInt8` with specified bit count 8
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let fieldBitCount = 8
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (UInt8).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.rawValue = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `value` of type `UInt8` with specified bit count 8
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        do {
                            let fieldBitCount = 8
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (UInt8).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.value = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `flag1` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        do {
                            let fieldBitCount = (Bool).bitCount
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Bool).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.flag1 = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
                        }
                        // Parse `flag2` of type `Bool` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        do {
                            let fieldBitCount = (Bool).bitCount
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Bool).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.flag2 = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    public init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `flag` of type `Bool` with specified bit count 1
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        do {
                            let fieldBitCount = 1
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Bool).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.flag = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
                    internal init(bits: RawBitsInteger) throws {
                        guard Self.bitCount <= RawBitsInteger.bitWidth else {
                            throw BinaryParseKit.BitmaskParsableError.rawBitsIntegerNotWideEnough
                        }
                        var bitPosition = 0
                        // Parse `a` of type `Flag` with inferred bit count
                        BinaryParseKit.__assertBitmaskParsable((Flag).self)
                        do {
                            let fieldBitCount = (Flag).bitCount
                            let shift = RawBitsInteger.bitWidth - bitPosition - fieldBitCount
                            let mask = RawBitsInteger((1 << fieldBitCount) - 1)
                            let fieldBits = (Flag).RawBitsInteger(truncatingIfNeeded: (bits >> shift) & mask)
                            self.a = try .init(bits: fieldBits)
                            bitPosition += fieldBitCount
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
