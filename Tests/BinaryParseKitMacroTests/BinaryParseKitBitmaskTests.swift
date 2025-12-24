import BinaryParseKitCommons
@testable import BinaryParseKitMacros
import MacroTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// swiftlint:disable line_length

extension BinaryParseKitMacroTests {
    @Suite
    struct `Bitmask Tests` {
        @Suite
        struct `Test ParseBitmask` { // swiftlint:disable:this type_name
            @Test
            func basicParseBitmaskExpansion() {
                assertMacro {
                    """
                    @ParseBitmask
                    struct Flags {
                        @mask(bitCount: 1)
                        var enabled: Bool

                        @mask(bitCount: 4)
                        var priority: UInt8

                        @mask(bitCount: 3)
                        var mode: UInt8
                    }
                    """
                } expansion: {
                    """
                    struct Flags {
                        var enabled: Bool
                        var priority: UInt8
                        var mode: UInt8
                    }

                    extension Flags: BinaryParseKit.BitmaskParsable {
                        internal static var bitCount: Int {
                            1 + 4 + 3
                        }
                        internal init(from bits: borrowing BinaryParseKit.RawBits) throws {
                            var bitOffset = 0
                            BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                            self.enabled = try BinaryParseKit.__parseFromBits((Bool).self, from: bits, offset: bitOffset, count: 1)
                            bitOffset += 1
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            self.priority = try BinaryParseKit.__parseFromBits((UInt8).self, from: bits, offset: bitOffset, count: 4)
                            bitOffset += 4
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            self.mode = try BinaryParseKit.__parseFromBits((UInt8).self, from: bits, offset: bitOffset, count: 3)
                            bitOffset += 3
                        }
                    }
                    """
                }
            }

            @Test
            func parseBitmaskWithInferredBitCount() {
                assertMacro {
                    """
                    @ParseBitmask
                    struct PackedData {
                        @mask
                        var value: UInt8

                        @mask(bitCount: 4)
                        var nibble: UInt8
                    }
                    """
                } expansion: {
                    """
                    struct PackedData {
                        var value: UInt8
                        var nibble: UInt8
                    }

                    extension PackedData: BinaryParseKit.BitmaskParsable {
                        internal static var bitCount: Int {
                            UInt8.bitCount + 4
                        }
                        internal init(from bits: borrowing BinaryParseKit.RawBits) throws {
                            var bitOffset = 0
                            BinaryParseKit.__assertBitmaskParsable((UInt8).self)
                            self.value = try BinaryParseKit.__parseFromBits((UInt8).self, from: bits, offset: bitOffset, count: UInt8.bitCount)
                            bitOffset += UInt8.bitCount
                            BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                            self.nibble = try BinaryParseKit.__parseFromBits((UInt8).self, from: bits, offset: bitOffset, count: 4)
                            bitOffset += 4
                        }
                    }
                    """
                }
            }

            @Test
            func parseBitmaskOnNonStruct() {
                assertMacro {
                    """
                    @ParseBitmask
                    class Flags {
                        @mask(bitCount: 8)
                        var value: UInt8
                    }
                    """
                } diagnostics: {
                    """
                    @ParseBitmask
                    ┬────────────
                    ╰─ 🛑 @ParseBitmask can only be applied to structs.
                    class Flags {
                        @mask(bitCount: 8)
                        var value: UInt8
                    }
                    """
                }
            }

            @Test
            func parseBitmaskOnEnum() {
                assertMacro {
                    """
                    @ParseBitmask
                    enum Flags {
                        case a
                    }
                    """
                } diagnostics: {
                    """
                    @ParseBitmask
                    ┬────────────
                    ╰─ 🛑 @ParseBitmask can only be applied to structs.
                    enum Flags {
                        case a
                    }
                    """
                }
            }

            @Test
            func parseBitmaskWithNoMaskFields() {
                assertMacro {
                    """
                    @ParseBitmask
                    struct Empty {
                        var computed: Int { 42 }
                    }
                    """
                } diagnostics: {
                    """
                    @ParseBitmask
                    ╰─ ⚠️ @ParseBitmask struct must have at least one @mask field.
                    struct Empty {
                        var computed: Int { 42 }
                    }
                    """
                } expansion: {
                    """
                    struct Empty {
                        var computed: Int { 42 }
                    }

                    extension Empty: BinaryParseKit.BitmaskParsable {
                        internal static var bitCount: Int {
                            0
                        }
                        internal init(from bits: borrowing BinaryParseKit.RawBits) throws {
                            var bitOffset = 0
                        }
                    }
                    """
                }
            }

            @Test
            func parseBitmaskFieldWithoutTypeAnnotation() {
                assertMacro {
                    """
                    @ParseBitmask
                    struct Flags {
                        @mask(bitCount: 8)
                        var value = 0
                    }
                    """
                } diagnostics: {
                    """
                    @ParseBitmask
                    ┬────────────
                    ╰─ 🛑 Parsing bitmask struct's fields has encountered an error.
                    struct Flags {
                        @mask(bitCount: 8)
                        var value = 0
                            ┬────────
                            ╰─ 🛑 Fields with @mask must have explicit type annotations.
                    }
                    """
                }
            }

            @Test
            func maskWithInvalidBitCount() {
                assertMacro {
                    """
                    @ParseBitmask
                    struct Flags {
                        @mask(bitCount: "invalid")
                        var value: UInt8
                    }
                    """
                } expansion: {
                    """
                    struct Flags {
                        var value: UInt8
                    }

                    extension Flags: BinaryParseKit.BitmaskParsable {
                        internal static var bitCount: Int {
                            UInt8.bitCount
                        }
                        internal init(from bits: borrowing BinaryParseKit.RawBits) throws {
                            var bitOffset = 0
                            BinaryParseKit.__assertBitmaskParsable((UInt8).self)
                            self.value = try BinaryParseKit.__parseFromBits((UInt8).self, from: bits, offset: bitOffset, count: UInt8.bitCount)
                            bitOffset += UInt8.bitCount
                        }
                    }
                    """
                }
            }
        }

        @Suite
        struct `Test parseBitmask in ParseStruct` { // swiftlint:disable:this type_name
            @Test
            func parseBitmaskFieldInStruct() {
                assertMacro {
                    """
                    @ParseStruct
                    struct Header {
                        @parse
                        var id: UInt8

                        @parseBitmask
                        var flags: PackedFlags

                        @parse
                        var checksum: UInt16
                    }
                    """
                } expansion: {
                    """
                    struct Header {
                        var id: UInt8
                        var flags: PackedFlags
                        var checksum: UInt16
                    }

                    extension Header: BinaryParseKit.Parsable {
                        internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                            // Parse `id` of type UInt8
                            BinaryParseKit.__assertParsable((UInt8).self)
                            self.id = try UInt8(parsing: &span)
                            // Parse `flags` of type PackedFlags as bitmask
                            BinaryParseKit.__assertBitmaskParsable((PackedFlags).self)
                            self.flags = try BinaryParseKit.__parseBitmask((PackedFlags).self, from: &span)
                            // Parse `checksum` of type UInt16
                            BinaryParseKit.__assertParsable((UInt16).self)
                            self.checksum = try UInt16(parsing: &span)
                        }
                    }

                    extension Header: BinaryParseKit.Printable {
                        internal func printerIntel() throws -> PrinterIntel {
                            return .struct(
                                .init(
                                    fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(id)), .init(byteCount: (PackedFlags.bitCount + 7) / 8, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(flags)), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(checksum))]
                                )
                            )
                        }
                    }
                    """
                }
            }

            @Test
            func multipleParseBitmaskFieldsInStruct() {
                assertMacro {
                    """
                    @ParseStruct
                    struct Packet {
                        @parseBitmask
                        var header: HeaderFlags

                        @parseBitmask
                        var payload: PayloadFlags
                    }
                    """
                } expansion: {
                    """
                    struct Packet {
                        var header: HeaderFlags
                        var payload: PayloadFlags
                    }

                    extension Packet: BinaryParseKit.Parsable {
                        internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                            // Parse `header` of type HeaderFlags as bitmask
                            BinaryParseKit.__assertBitmaskParsable((HeaderFlags).self)
                            self.header = try BinaryParseKit.__parseBitmask((HeaderFlags).self, from: &span)
                            // Parse `payload` of type PayloadFlags as bitmask
                            BinaryParseKit.__assertBitmaskParsable((PayloadFlags).self)
                            self.payload = try BinaryParseKit.__parseBitmask((PayloadFlags).self, from: &span)
                        }
                    }

                    extension Packet: BinaryParseKit.Printable {
                        internal func printerIntel() throws -> PrinterIntel {
                            return .struct(
                                .init(
                                    fields: [.init(byteCount: (HeaderFlags.bitCount + 7) / 8, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(header)), .init(byteCount: (PayloadFlags.bitCount + 7) / 8, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(payload))]
                                )
                            )
                        }
                    }
                    """
                }
            }
        }

        @Suite
        struct `Test parseBitmask in ParseEnum` { // swiftlint:disable:this type_name
            @Test
            func parseBitmaskInEnumAssociatedValue() {
                assertMacro {
                    """
                    @ParseEnum
                    enum Message {
                        @match(byte: 0x01)
                        @parseBitmask
                        case flags(PackedFlags)

                        @matchDefault
                        case unknown
                    }
                    """
                } expansion: {
                    #"""
                    enum Message {
                        case flags(PackedFlags)
                        case unknown
                    }

                    extension Message: BinaryParseKit.Parsable {
                        internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                            if BinaryParseKit.__match([0x01], in: &span) {
                                // Parse `__macro_local_15Message_flags_0fMu_` of type PackedFlags as bitmask
                                BinaryParseKit.__assertBitmaskParsable((PackedFlags).self)
                                let __macro_local_15Message_flags_0fMu_ = try BinaryParseKit.__parseBitmask((PackedFlags).self, from: &span)
                                // construct `flags` with above associated values
                                self = .flags(__macro_local_15Message_flags_0fMu_)
                                return
                            }
                            if true {
                                self = .unknown
                                return
                            }
                            throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for Message, at \(span.startPosition)")
                        }
                    }

                    extension Message: BinaryParseKit.Printable {
                        internal func printerIntel() throws -> PrinterIntel {
                            switch self {
                            case let .flags(__macro_local_13flags_index_0fMu_):
                                let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                                return .enum(
                                    .init(
                                        bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                        parseType: .match,
                                        fields: [.init(byteCount: (PackedFlags.bitCount + 7) / 8, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_13flags_index_0fMu_))],
                                    )
                                )
                            case .unknown:
                                let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = []
                                return .enum(
                                    .init(
                                        bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                        parseType: .matchDefault,
                                        fields: [],
                                    )
                                )
                            }
                        }
                    }
                    """#
                }
            }

            @Test
            func parseBitmaskWithNamedAssociatedValue() {
                assertMacro {
                    """
                    @ParseEnum
                    enum Command {
                        @match(byte: 0x01)
                        @parseBitmask
                        case configure(options: ConfigFlags)

                        @matchDefault
                        case other
                    }
                    """
                } expansion: {
                    #"""
                    enum Command {
                        case configure(options: ConfigFlags)
                        case other
                    }

                    extension Command: BinaryParseKit.Parsable {
                        internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                            if BinaryParseKit.__match([0x01], in: &span) {
                                // Parse `options` of type ConfigFlags as bitmask
                                BinaryParseKit.__assertBitmaskParsable((ConfigFlags).self)
                                let options = try BinaryParseKit.__parseBitmask((ConfigFlags).self, from: &span)
                                // construct `configure` with above associated values
                                self = .configure(options: options)
                                return
                            }
                            if true {
                                self = .other
                                return
                            }
                            throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for Command, at \(span.startPosition)")
                        }
                    }

                    extension Command: BinaryParseKit.Printable {
                        internal func printerIntel() throws -> PrinterIntel {
                            switch self {
                            case let .configure(__macro_local_17configure_optionsfMu_):
                                let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                                return .enum(
                                    .init(
                                        bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                        parseType: .match,
                                        fields: [.init(byteCount: (ConfigFlags.bitCount + 7) / 8, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_17configure_optionsfMu_))],
                                    )
                                )
                            case .other:
                                let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = []
                                return .enum(
                                    .init(
                                        bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                        parseType: .matchDefault,
                                        fields: [],
                                    )
                                )
                            }
                        }
                    }
                    """#
                }
            }

            @Test
            func mixedParseAndParseBitmaskInEnum() {
                assertMacro {
                    """
                    @ParseEnum
                    enum Data {
                        @match(byte: 0x01)
                        @parse
                        @parseBitmask
                        case mixed(UInt8, PackedFlags)

                        @matchDefault
                        case other
                    }
                    """
                } expansion: {
                    #"""
                    enum Data {
                        case mixed(UInt8, PackedFlags)
                        case other
                    }

                    extension Data: BinaryParseKit.Parsable {
                        internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                            if BinaryParseKit.__match([0x01], in: &span) {
                                // Parse `__macro_local_12Data_mixed_0fMu_` of type UInt8
                                BinaryParseKit.__assertParsable((UInt8).self)
                                let __macro_local_12Data_mixed_0fMu_ = try UInt8(parsing: &span)
                                // Parse `__macro_local_12Data_mixed_1fMu_` of type PackedFlags as bitmask
                                BinaryParseKit.__assertBitmaskParsable((PackedFlags).self)
                                let __macro_local_12Data_mixed_1fMu_ = try BinaryParseKit.__parseBitmask((PackedFlags).self, from: &span)
                                // construct `mixed` with above associated values
                                self = .mixed(__macro_local_12Data_mixed_0fMu_, __macro_local_12Data_mixed_1fMu_)
                                return
                            }
                            if true {
                                self = .other
                                return
                            }
                            throw BinaryParseKit.BinaryParserKitError.failedToParse("Failed to find a match for Data, at \(span.startPosition)")
                        }
                    }

                    extension Data: BinaryParseKit.Printable {
                        internal func printerIntel() throws -> PrinterIntel {
                            switch self {
                            case let .mixed(__macro_local_13mixed_index_0fMu_, __macro_local_13mixed_index_1fMu_):
                                let __macro_local_20bytesTakenInMatchingfMu_: [UInt8] = [0x01]
                                return .enum(
                                    .init(
                                        bytes: __macro_local_20bytesTakenInMatchingfMu_,
                                        parseType: .match,
                                        fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_13mixed_index_0fMu_)), .init(byteCount: (PackedFlags.bitCount + 7) / 8, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(__macro_local_13mixed_index_1fMu_))],
                                    )
                                )
                            case .other:
                                let __macro_local_20bytesTakenInMatchingfMu0_: [UInt8] = []
                                return .enum(
                                    .init(
                                        bytes: __macro_local_20bytesTakenInMatchingfMu0_,
                                        parseType: .matchDefault,
                                        fields: [],
                                    )
                                )
                            }
                        }
                    }
                    """#
                }
            }
        }
    }
}

// swiftlint:enable line_length
