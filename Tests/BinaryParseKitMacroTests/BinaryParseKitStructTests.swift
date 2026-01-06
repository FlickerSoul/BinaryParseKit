import BinaryParseKitCommons
@testable import BinaryParseKitMacros
import MacroTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// swiftlint:disable line_length file_length

extension BinaryParseKitMacroTests {
    @Suite
    struct `Test Parsing Struct` { // swiftlint:disable:this type_body_length
        @Test
        func successfulParseStructMacroExpansion() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: 1, endianness: .big)
                    let a: Int

                    @parse(endianness: .little)
                    let b: Int32

                    @skip(byteCount: 2, reason: "not needed")
                    @skip(byteCount: 4, reason: "also not needed")
                    @parse(endianness: .big)
                    let d: Float16

                    @parse()
                    let c: CustomValue

                    @skip(byteCount: 6, reason: "again, not needed")
                    @parse
                    let e: CustomValue

                    @parse(byteCountOf: \Self.b)
                    var g: CustomValue

                    @skip(byteCount: 7, reason: "last one skip")
                    @parseRest(endianness: .little)
                    let f: CustomValue

                    var computedF: CustomValue {
                        CustomValue()
                    }

                    var computeG: CustomValue {
                        get { g }
                        set { g = newValue }
                    }
                }
                """#
            } expansion: {
                """
                public struct Header {
                    let a: Int
                    let b: Int32
                    let d: Float16
                    let c: CustomValue
                    let e: CustomValue
                    var g: CustomValue
                    let f: CustomValue

                    var computedF: CustomValue {
                        CustomValue()
                    }

                    var computeG: CustomValue {
                        get { g }
                        set { g = newValue }
                    }
                }

                extension Header: BinaryParseKit.Parsable {
                    public init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        // Parse `a` of type Int with endianness and byte count
                        BinaryParseKit.__assertEndianSizedParsable((Int).self)
                        self.a = try Int(parsing: &span, endianness: .big, byteCount: 1)
                        // Parse `b` of type Int32 with endianness
                        BinaryParseKit.__assertEndianParsable((Int32).self)
                        self.b = try Int32(parsing: &span, endianness: .little)
                        // Skip 2 because of "not needed", before parsing `d`
                        try span.seek(toRelativeOffset: 2)
                        // Skip 4 because of "also not needed", before parsing `d`
                        try span.seek(toRelativeOffset: 4)
                        // Parse `d` of type Float16 with endianness
                        BinaryParseKit.__assertEndianParsable((Float16).self)
                        self.d = try Float16(parsing: &span, endianness: .big)
                        // Parse `c` of type CustomValue
                        BinaryParseKit.__assertParsable((CustomValue).self)
                        self.c = try CustomValue(parsing: &span)
                        // Skip 6 because of "again, not needed", before parsing `e`
                        try span.seek(toRelativeOffset: 6)
                        // Parse `e` of type CustomValue
                        BinaryParseKit.__assertParsable((CustomValue).self)
                        self.e = try CustomValue(parsing: &span)
                        // Parse `g` of type CustomValue with byte count
                        BinaryParseKit.__assertSizedParsable((CustomValue).self)
                        self.g = try CustomValue(parsing: &span, byteCount: Int(self.b))
                        // Skip 7 because of "last one skip", before parsing `f`
                        try span.seek(toRelativeOffset: 7)
                        // Parse `f` of type CustomValue with endianness and byte count
                        BinaryParseKit.__assertEndianSizedParsable((CustomValue).self)
                        self.f = try CustomValue(parsing: &span, endianness: .little, byteCount: span.endPosition - span.startPosition)
                    }
                }

                extension Header: BinaryParseKit.Printable {
                    public func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: Swift.Int(1), endianness: .big, intel: try BinaryParseKit.__getPrinterIntel(a)), .init(byteCount: nil, endianness: .little, intel: try BinaryParseKit.__getPrinterIntel(b)), .init(byteCount: Swift.Int(2), endianness: nil, intel: .skip(.init(byteCount: Swift.Int(2)))), .init(byteCount: Swift.Int(4), endianness: nil, intel: .skip(.init(byteCount: Swift.Int(4)))), .init(byteCount: nil, endianness: .big, intel: try BinaryParseKit.__getPrinterIntel(d)), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(c)), .init(byteCount: Swift.Int(6), endianness: nil, intel: .skip(.init(byteCount: Swift.Int(6)))), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(e)), .init(byteCount: Swift.Int(self.b), endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(g)), .init(byteCount: Swift.Int(7), endianness: nil, intel: .skip(.init(byteCount: Swift.Int(7)))), .init(byteCount: nil, endianness: .little, intel: try BinaryParseKit.__getPrinterIntel(f))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func parseStructOnClass() {
            assertMacro {
                #"""
                @ParseStruct
                public class Header {
                    @parse
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 @ParseStruct only supports structs. Please use a struct declaration or other macros.
                public class Header {
                    @parse
                    let a: Int
                }
                """
            }
        }

        @Test
        func parseStructOnEnum() {
            assertMacro {
                #"""
                @ParseStruct
                public enum Header {
                    case a
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 @ParseStruct only supports structs. Please use a struct declaration or other macros.
                public enum Header {
                    case a
                }
                """
            }
        }

        @Test
        func variableWithoutTypeAnnotation() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse
                    var a = 1
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse
                    var a = 1
                        ┬────
                        ╰─ 🛑 Variable declarations must have a type annotation to be parsed.
                }
                """
            }
        }

        @Test
        func variableWithoutParseAttribute() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    let a: Int
                        ┬─────
                        ╰─ 🛑 The variable declaration must have a `@parse` attribute.
                }
                """
            }
        }

        @Test
        func multipleParseRestAttributes() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parseRest
                    let a: Data
                    @parseRest
                    let b: Data
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parseRest
                    let a: Data
                    @parseRest
                    let b: Data
                        ┬──────
                        ╰─ 🛑 Multiple or non-trailing `@parseRest` attributes are not allowed. Only one trailing `@parseRest` is permitted.
                }
                """
            }
        }

        @Test
        func nonTrailingParseRest() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parseRest
                    let a: Data
                    @parse
                    let b: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parseRest
                    let a: Data
                    @parse
                    let b: Int
                        ┬─────
                        ╰─ 🛑 Multiple or non-trailing `@parseRest` attributes are not allowed. Only one trailing `@parseRest` is permitted.
                }
                """
            }
        }

        @Test
        func emptyStructWithNoParseableFields() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    static let constant = 42
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ╰─ ⚠️ No variables with `@parse` attribute found in the struct. Ensure at least one variable is marked for parsing.
                public struct Header {
                    static let constant = 42
                }
                """
            } expansion: {
                """
                public struct Header {
                    static let constant = 42
                }

                extension Header: BinaryParseKit.Parsable {
                    public init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                    }
                }

                extension Header: BinaryParseKit.Printable {
                    public func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: []
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func invalidVariablePattern() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse
                    let (a, b): (Int, Int)
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse
                    let (a, b): (Int, Int)
                        ┬─────────────────
                        ╰─ 🛑 Variable declaration must be an identifier definition.
                }
                """
            }
        }

        @Test
        func invalidParseAttributeArgument() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse(unknownArgument: 42)
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse(unknownArgument: 42)
                           ┬──────────────────
                    │      ╰─ 🛑 Unknown argument in `@parse`: 'unknownArgument'. Please check the attribute syntax.
                    ┬──────────────────────────
                    ├─ 🛑 Fatal error: @parse argument validation failed.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    let a: Int
                }
                """
            }
        }

        @Test
        func conflictingByteCountArguments() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: 4, byteCountOf: \Self.someField)
                    let a: Int
                }
                """#
            } diagnostics: {
                #"""
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse(byteCount: 4, byteCountOf: \Self.someField)
                    ┬─────────────────────────────────────────────────
                    ├─ 🛑 Fatal error: Both `byteCountOf` and `byteCount` cannot be specified at the same time.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    let a: Int
                }
                """#
            }
        }

        @Test
        func invalidByteCountLiteral() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: "invalid")
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse(byteCount: "invalid")
                    ┬───────────────────────────
                    ├─ 🛑 Failed expectation: byteCount should be an integer literal.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    let a: Int
                }
                """
            }
        }

        @Test
        func invalidByteCountOfKeyPath() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCountOf: "notAKeyPath")
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse(byteCountOf: "notAKeyPath")
                    ┬─────────────────────────────────
                    ├─ 🛑 Failed expectation: byteCountOf should be a KeyPath literal expression.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    let a: Int
                }
                """
            }
        }

        @Test
        func skipWithMissingArguments() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @skip
                    @parse
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @skip
                    ┬────
                    ├─ 🛑 Failed expectation: Expected a labeled expression list for `@parseSkip` attribute, but found none.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    @parse
                    let a: Int
                }
                """
            }
        }

        @Test
        func skipWithWrongNumberOfArguments() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @skip(byteCount: 4)
                    @parse
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @skip(byteCount: 4)
                    ┬──────────────────
                    ├─ 🛑 Fatal error: Expected exactly two arguments for `@parseSkip` attribute, but found 1.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    @parse
                    let a: Int
                }
                """
            }
        }

        @Test
        func skipWithInvalidByteCount() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @skip(byteCount: "invalid", reason: "test")
                    @parse
                    let a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @skip(byteCount: "invalid", reason: "test")
                    ┬──────────────────────────────────────────
                    ├─ 🛑 Failed expectation: Expected the first argument of `@parseSkip` to be an integer literal representing byte count.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    @parse
                    let a: Int
                }
                """
            }
        }

        @Test
        func computedPropertyWithParse() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse
                    var a: Int {
                        get { 42 }
                        set { }
                    }
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse
                    var a: Int {
                        ╰─ 🛑 The variable declaration with accessor(s) (`get` and `set`) cannot be parsed.
                        get { 42 }
                        set { }
                    }
                }
                """
            }
        }

        @Test
        func byteCountParseConvertInParse() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: 0xFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF)
                    var a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @parse(byteCount: 0xFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF)
                    ┬────────────────────────────────────────────────────────────────
                    ├─ 🛑 Failed expectation: byteCount should be convertible to Int.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    var a: Int
                }
                """
            }
        }

        @Test
        func byteCountParseConvertInSkip() {
            assertMacro {
                #"""
                @ParseStruct
                public struct Header {
                    @skip(byteCount: 0xFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, because: "test bad byte count")
                    @parse
                    var a: Int
                }
                """#
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                public struct Header {
                    @skip(byteCount: 0xFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, because: "test bad byte count")
                    ┬───────────────────────────────────────────────────────────────────────────────────────────────
                    ├─ 🛑 Failed expectation: byteCount should be convertible to Int.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    @parse
                    var a: Int
                }
                """
            }
        }

        @Test
        func `no comments and spaces in code generation`() {
            assertMacro {
                """
                @ParseStruct
                struct Header {
                    @parse
                    var a: Int  // some comments

                    @parse
                    var b: // some comments
                            Int // some comments

                    @parse
                    var  // some comments
                        c: // some comments
                            Int // some comments
                }
                """
            } expansion: {
                """
                struct Header {
                    var a: Int  // some comments
                    var b: // some comments
                            Int // some comments
                    var  // some comments
                        c: // some comments
                            Int // some comments
                }

                extension Header: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        // Parse `a` of type Int
                        BinaryParseKit.__assertParsable((Int).self)
                        self.a = try Int(parsing: &span)
                        // Parse `b` of type Int
                        BinaryParseKit.__assertParsable((Int).self)
                        self.b = try Int(parsing: &span)
                        // Parse `c` of type Int
                        BinaryParseKit.__assertParsable((Int).self)
                        self.c = try Int(parsing: &span)
                    }
                }

                extension Header: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(a)), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(b)), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(c))]
                            )
                        )
                    }
                }
                """
            }
        }

        struct StructAccessorTestCase: Codable {
            let arguments: String
            let parsingAccessor: ExtensionAccessor
            let printingAccessor: ExtensionAccessor
        }

        @Test(
            arguments: [
                // String literal
                .init(
                    arguments: #"parsingAccessor: "public", printingAccessor: "public""#,
                    parsingAccessor: .public,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: "public""#,
                    parsingAccessor: .public,
                    printingAccessor: .internal,
                ),
                .init(
                    arguments: #"printingAccessor: "public""#,
                    parsingAccessor: .internal,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: "private", printingAccessor: "package""#,
                    parsingAccessor: .private,
                    printingAccessor: .package,
                ),
                // member access
                .init(
                    arguments: #"parsingAccessor: .public, printingAccessor: .public"#,
                    parsingAccessor: .public,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: .public"#,
                    parsingAccessor: .public,
                    printingAccessor: .internal,
                ),
                .init(
                    arguments: #"printingAccessor: .public"#,
                    parsingAccessor: .internal,
                    printingAccessor: .public,
                ),
                .init(
                    arguments: #"parsingAccessor: .private, printingAccessor: .package"#,
                    parsingAccessor: .private,
                    printingAccessor: .package,
                ),
            ] as [StructAccessorTestCase],
        )
        func `struct accessor`(testCase: StructAccessorTestCase) {
            assertMacro(record: .never) {
                """
                // \(testCase.arguments)
                @ParseStruct(\(testCase.arguments))
                struct TestStruct {
                    @parse
                    let value: Value
                }
                """
            } expansion: {
                """
                // \(testCase.arguments)
                struct TestStruct {
                    let value: Value
                }

                extension TestStruct: BinaryParseKit.Parsable {
                    \(testCase.parsingAccessor
                    .description) init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        // Parse `value` of type Value
                        BinaryParseKit.__assertParsable((Value).self)
                        self.value = try Value(parsing: &span)
                    }
                }

                extension TestStruct: BinaryParseKit.Printable {
                    \(testCase.printingAccessor.description) func printerIntel() throws -> PrinterIntel {
                        return .struct(
                            .init(
                                fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(value))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func `struct bad accessor`() {
            assertMacro {
                """
                @ParseStruct(parsingAccessor: "invalid", printingAccessor: .invalid)
                struct TestStruct {
                    @parse
                    let value: Value
                }
                """
            } diagnostics: {
                """
                @ParseStruct(parsingAccessor: "invalid", printingAccessor: .invalid)
                                                         ┬─────────────────────────
                │            │                           ╰─ 🛑 Invalid ACL value: invalid; Please use one of public, package, internal, fileprivate, private, follow; use it in string literal "public" or enum member access .public.
                             ┬──────────────────────────
                │            ╰─ 🛑 Invalid ACL value: invalid; Please use one of public, package, internal, fileprivate, private, follow; use it in string literal "public" or enum member access .public.
                ┬───────────────────────────────────────────────────────────────────
                ╰─ 🛑 You have used unknown accessor in `@ParseStruct` or `@ParseEnum`.
                struct TestStruct {
                    @parse
                    let value: Value
                }
                """
            }
        }

        @Test
        func `mask fields in struct`() {
            assertMacro {
                """
                @ParseStruct
                struct BitFlags {
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
                struct BitFlags {
                    var flag1: Bool
                    var value: UInt8
                    var flag2: Bool
                }

                extension BitFlags: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        // Parse bitmask fields
                        let __macro_local_19__bitmask_totalBitsfMu_ = 1 + 3 + (Bool).bitCount
                        let __macro_local_19__bitmask_byteCountfMu_ = (__macro_local_19__bitmask_totalBitsfMu_ + 7) / 8
                        let __macro_local_14__bitmask_spanfMu_ = try span.sliceSpan(byteCount: __macro_local_19__bitmask_byteCountfMu_)
                        var __macro_local_16__bitmask_offsetfMu_ = 0
                        // Parse `flag1` of type Bool from bits
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        self.flag1 = try .init(bits: BinaryParseKit.__extractBitsAsInteger((Bool).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 1))
                        __macro_local_16__bitmask_offsetfMu_ += 1
                        // Parse `value` of type UInt8 from bits
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        self.value = try .init(bits: BinaryParseKit.__extractBitsAsInteger((UInt8).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 3))
                        __macro_local_16__bitmask_offsetfMu_ += 3
                        // Parse `flag2` of type Bool from bits
                        BinaryParseKit.__assertBitmaskParsable((Bool).self)
                        self.flag2 = try .init(bits: BinaryParseKit.__extractBitsAsInteger((Bool).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: (Bool).bitCount))
                        __macro_local_16__bitmask_offsetfMu_ += (Bool).bitCount
                    }
                }

                extension BitFlags: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        // bits from flag1, value, flag2
                        let __macro_local_10__maskBitsfMu_ = try BinaryParseKit.__toRawBits(flag1, bitCount: 1).appending(BinaryParseKit.__toRawBits(value, bitCount: 3)).appending(BinaryParseKit.__toRawBits(flag2, bitCount: (Bool).bitCount))
                        return .struct(
                            .init(
                                fields: [.init(byteCount: nil, endianness: nil, intel: .bitmask(.init(bits: __macro_local_10__maskBitsfMu_)))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func `mixed parse and mask fields in struct`() {
            assertMacro {
                """
                @ParseStruct
                struct MixedStruct {
                    @parse
                    var header: UInt8

                    @mask(bitCount: 1)
                    var flag: Bool

                    @mask(bitCount: 7)
                    var data: UInt8

                    @parse
                    var footer: UInt16
                }
                """
            } expansion: {
                """
                struct MixedStruct {
                    var header: UInt8
                    var flag: Bool
                    var data: UInt8
                    var footer: UInt16
                }

                extension MixedStruct: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        // Parse `header` of type UInt8
                        BinaryParseKit.__assertParsable((UInt8).self)
                        self.header = try UInt8(parsing: &span)
                        // Parse bitmask fields
                        let __macro_local_19__bitmask_totalBitsfMu_ = 1 + 7
                        let __macro_local_19__bitmask_byteCountfMu_ = (__macro_local_19__bitmask_totalBitsfMu_ + 7) / 8
                        let __macro_local_14__bitmask_spanfMu_ = try span.sliceSpan(byteCount: __macro_local_19__bitmask_byteCountfMu_)
                        var __macro_local_16__bitmask_offsetfMu_ = 0
                        // Parse `flag` of type Bool from bits
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        self.flag = try .init(bits: BinaryParseKit.__extractBitsAsInteger((Bool).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 1))
                        __macro_local_16__bitmask_offsetfMu_ += 1
                        // Parse `data` of type UInt8 from bits
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        self.data = try .init(bits: BinaryParseKit.__extractBitsAsInteger((UInt8).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 7))
                        __macro_local_16__bitmask_offsetfMu_ += 7
                        // Parse `footer` of type UInt16
                        BinaryParseKit.__assertParsable((UInt16).self)
                        self.footer = try UInt16(parsing: &span)
                    }
                }

                extension MixedStruct: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        // bits from flag, data
                        let __macro_local_10__maskBitsfMu_ = try BinaryParseKit.__toRawBits(flag, bitCount: 1).appending(BinaryParseKit.__toRawBits(data, bitCount: 7))
                        return .struct(
                            .init(
                                fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(header)), .init(byteCount: nil, endianness: nil, intel: .bitmask(.init(bits: __macro_local_10__maskBitsfMu_))), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(footer))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func `alternate mask and parse fields in struct`() {
            assertMacro {
                """
                @ParseStruct
                struct MixedStruct {
                    @parse
                    var header: UInt8

                    @mask(bitCount: 1)
                    var topFlag: Bool

                    @mask(bitCount: 4)
                    var topData: UInt8

                    @parse
                    var divider: UInt16

                    @mask(bitCount: 1)
                    var bottomFlag: Bool

                    @mask(bitCount: 4)
                    var bottomData: UInt8

                    @mask(bitCount: 2)
                    var bottomAdditionalData: UInt8

                    @parse
                    var footer: UInt16
                }
                """
            } expansion: {
                """
                struct MixedStruct {
                    var header: UInt8
                    var topFlag: Bool
                    var topData: UInt8
                    var divider: UInt16
                    var bottomFlag: Bool
                    var bottomData: UInt8
                    var bottomAdditionalData: UInt8
                    var footer: UInt16
                }

                extension MixedStruct: BinaryParseKit.Parsable {
                    internal init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                        // Parse `header` of type UInt8
                        BinaryParseKit.__assertParsable((UInt8).self)
                        self.header = try UInt8(parsing: &span)
                        // Parse bitmask fields
                        let __macro_local_19__bitmask_totalBitsfMu_ = 1 + 4
                        let __macro_local_19__bitmask_byteCountfMu_ = (__macro_local_19__bitmask_totalBitsfMu_ + 7) / 8
                        let __macro_local_14__bitmask_spanfMu_ = try span.sliceSpan(byteCount: __macro_local_19__bitmask_byteCountfMu_)
                        var __macro_local_16__bitmask_offsetfMu_ = 0
                        // Parse `topFlag` of type Bool from bits
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        self.topFlag = try .init(bits: BinaryParseKit.__extractBitsAsInteger((Bool).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 1))
                        __macro_local_16__bitmask_offsetfMu_ += 1
                        // Parse `topData` of type UInt8 from bits
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        self.topData = try .init(bits: BinaryParseKit.__extractBitsAsInteger((UInt8).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu_, offset: __macro_local_16__bitmask_offsetfMu_, count: 4))
                        __macro_local_16__bitmask_offsetfMu_ += 4
                        // Parse `divider` of type UInt16
                        BinaryParseKit.__assertParsable((UInt16).self)
                        self.divider = try UInt16(parsing: &span)
                        // Parse bitmask fields
                        let __macro_local_19__bitmask_totalBitsfMu0_ = 1 + 4 + 2
                        let __macro_local_19__bitmask_byteCountfMu0_ = (__macro_local_19__bitmask_totalBitsfMu0_ + 7) / 8
                        let __macro_local_14__bitmask_spanfMu0_ = try span.sliceSpan(byteCount: __macro_local_19__bitmask_byteCountfMu0_)
                        var __macro_local_16__bitmask_offsetfMu0_ = 0
                        // Parse `bottomFlag` of type Bool from bits
                        BinaryParseKit.__assertExpressibleByRawBits((Bool).self)
                        self.bottomFlag = try .init(bits: BinaryParseKit.__extractBitsAsInteger((Bool).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu0_, offset: __macro_local_16__bitmask_offsetfMu0_, count: 1))
                        __macro_local_16__bitmask_offsetfMu0_ += 1
                        // Parse `bottomData` of type UInt8 from bits
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        self.bottomData = try .init(bits: BinaryParseKit.__extractBitsAsInteger((UInt8).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu0_, offset: __macro_local_16__bitmask_offsetfMu0_, count: 4))
                        __macro_local_16__bitmask_offsetfMu0_ += 4
                        // Parse `bottomAdditionalData` of type UInt8 from bits
                        BinaryParseKit.__assertExpressibleByRawBits((UInt8).self)
                        self.bottomAdditionalData = try .init(bits: BinaryParseKit.__extractBitsAsInteger((UInt8).RawBitsInteger.self, from: __macro_local_14__bitmask_spanfMu0_, offset: __macro_local_16__bitmask_offsetfMu0_, count: 2))
                        __macro_local_16__bitmask_offsetfMu0_ += 2
                        // Parse `footer` of type UInt16
                        BinaryParseKit.__assertParsable((UInt16).self)
                        self.footer = try UInt16(parsing: &span)
                    }
                }

                extension MixedStruct: BinaryParseKit.Printable {
                    internal func printerIntel() throws -> PrinterIntel {
                        // bits from topFlag, topData
                        let __macro_local_10__maskBitsfMu_ = try BinaryParseKit.__toRawBits(topFlag, bitCount: 1).appending(BinaryParseKit.__toRawBits(topData, bitCount: 4))
                        // bits from bottomFlag, bottomData, bottomAdditionalData
                        let __macro_local_10__maskBitsfMu0_ = try BinaryParseKit.__toRawBits(bottomFlag, bitCount: 1).appending(BinaryParseKit.__toRawBits(bottomData, bitCount: 4)).appending(BinaryParseKit.__toRawBits(bottomAdditionalData, bitCount: 2))
                        return .struct(
                            .init(
                                fields: [.init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(header)), .init(byteCount: nil, endianness: nil, intel: .bitmask(.init(bits: __macro_local_10__maskBitsfMu_))), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(divider)), .init(byteCount: nil, endianness: nil, intel: .bitmask(.init(bits: __macro_local_10__maskBitsfMu0_))), .init(byteCount: nil, endianness: nil, intel: try BinaryParseKit.__getPrinterIntel(footer))]
                            )
                        )
                    }
                }
                """
            }
        }

        @Test
        func `struct with non-positive bit count in mask`() {
            assertMacro {
                """
                @ParseStruct
                struct InvalidMaskStruct {
                    @mask(bitCount: -1)
                    var flag: Bool
                }
                """
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                struct InvalidMaskStruct {
                    @mask(bitCount: -1)
                    ┬──────────────────
                    ├─ 🛑 The bitCount argument must be a positive integer.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    var flag: Bool
                }
                """
            }

            assertMacro {
                """
                @ParseStruct
                struct InvalidMaskStruct {
                    @mask(bitCount: 0)
                    var flag: Bool
                }
                """
            } diagnostics: {
                """
                @ParseStruct
                ┬───────────
                ╰─ 🛑 Fatal error: Parsing struct's fields has encountered an error.
                struct InvalidMaskStruct {
                    @mask(bitCount: 0)
                    ┬─────────────────
                    ├─ 🛑 The bitCount argument must be a positive integer.
                    ╰─ 🛑 Fatal error: Encountered errors during parsing field.
                    var flag: Bool
                }
                """
            }
        }
    }
}

// swiftlint:enable line_length file_length
