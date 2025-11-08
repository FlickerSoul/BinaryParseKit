@testable import BinaryParseKitMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

extension BinaryParseKitMacroTests {
    @Suite
    struct `Test Parsing Struct` { // swiftlint:disable:this type_name type_body_length
        @Test
        func successfulParseStructMacroExpansion() {
            assertMacroExpansion(
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
                """#,
                expandedSource: """
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
                        BinaryParseKit.__assertEndianSizedParsable(Int.self)
                        self.a = try Int(parsing: &span, endianness: .big, byteCount: 1)
                        // Parse `b` of type Int32 with endianness
                        BinaryParseKit.__assertEndianParsable(Int32.self)
                        self.b = try Int32(parsing: &span, endianness: .little)
                        // Skip 2 because of "not needed", before parsing `d`
                        try span.seek(toRelativeOffset: 2)
                        // Skip 4 because of "also not needed", before parsing `d`
                        try span.seek(toRelativeOffset: 4)
                        // Parse `d` of type Float16 with endianness
                        BinaryParseKit.__assertEndianParsable(Float16.self)
                        self.d = try Float16(parsing: &span, endianness: .big)
                        // Parse `c` of type CustomValue
                        BinaryParseKit.__assertParsable(CustomValue.self)
                        self.c = try CustomValue(parsing: &span)
                        // Skip 6 because of "again, not needed", before parsing `e`
                        try span.seek(toRelativeOffset: 6)
                        // Parse `e` of type CustomValue
                        BinaryParseKit.__assertParsable(CustomValue.self)
                        self.e = try CustomValue(parsing: &span)
                        // Parse `g` of type CustomValue with byte count
                        BinaryParseKit.__assertSizedParsable(CustomValue.self)
                        self.g = try CustomValue(parsing: &span, byteCount: Int(self.b))
                        // Skip 7 because of "last one skip", before parsing `f`
                        try span.seek(toRelativeOffset: 7)
                        // Parse `f` of type CustomValue with endianness and byte count
                        BinaryParseKit.__assertEndianSizedParsable(CustomValue.self)
                        self.f = try CustomValue(parsing: &span, endianness: .little, byteCount: span.endPosition - span.startPosition)
                    }
                }
                """,
            )
        }

        @Test
        func parseStructOnClass() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public class Header {
                    @parse
                    let a: Int
                }
                """#,
                expandedSource: """
                public class Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.onlyStructsAreSupported,
                        line: 1,
                        column: 1,
                    ),
                ],
            )
        }

        @Test
        func parseStructOnEnum() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public enum Header {
                    case a
                }
                """#,
                expandedSource: """
                public enum Header {
                    case a
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.onlyStructsAreSupported,
                        line: 1,
                        column: 1,
                    ),
                ],
            )
        }

        @Test
        func variableWithoutTypeAnnotation() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse
                    let a = 1
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a = 1
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.variableDeclNoTypeAnnotation,
                        line: 4,
                        column: 9,
                    ),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func variableWithoutParseAttribute() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.noParseAttributeOnVariableDecl,
                        line: 3,
                        column: 9,
                    ),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func multipleParseRestAttributes() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parseRest
                    let a: Data
                    @parseRest
                    let b: Data
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Data
                    let b: Data
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.multipleOrNonTrailingParseRest,
                        line: 6,
                        column: 9,
                    ),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func nonTrailingParseRest() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parseRest
                    let a: Data
                    @parse
                    let b: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Data
                    let b: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.multipleOrNonTrailingParseRest,
                        line: 6,
                        column: 9,
                    ),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func emptyStructWithNoParseableFields() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    static let constant = 42
                }
                """#,
                expandedSource: """
                public struct Header {
                    static let constant = 42
                }

                extension Header: BinaryParseKit.Parsable {
                    public init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                    }
                }
                """,
                diagnostics: [
                    noParseVarExist,
                ],
            )
        }

        @Test
        func invalidVariablePattern() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse
                    let (a, b): (Int, Int)
                }
                """#,
                expandedSource: """
                public struct Header {
                    let (a, b): (Int, Int)
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.notIdentifierDef,
                        line: 4,
                        column: 9,
                    ),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func invalidParseAttributeArgument() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse(unknownArgument: 42)
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.unknownParseArgument("unknownArgument"),
                        line: 3,
                        column: 12,
                    ),
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.fatalError(message: "@parse argument validation failed."),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func conflictingByteCountArguments() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: 4, byteCountOf: \Self.someField)
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.fatalError(
                            message: "Both `byteCountOf` and `byteCount` cannot be specified at the same time.",
                        ),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func invalidByteCountLiteral() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: "invalid")
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError
                            .failedExpectation(message: "byteCount should be an integer literal."),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func invalidByteCountOfKeyPath() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCountOf: "notAKeyPath")
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError
                            .failedExpectation(message: "byteCountOf should be a KeyPath literal expression."),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func skipWithMissingArguments() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @skip
                    @parse
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.failedExpectation(
                            message: "Expected a labeled expression list for `@parseSkip` attribute, but found none.",
                        ),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func skipWithWrongNumberOfArguments() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @skip(byteCount: 4)
                    @parse
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.fatalError(
                            message: "Expected exactly two arguments for `@parseSkip` attribute, but found 1.",
                        ),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func skipWithInvalidByteCount() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @skip(byteCount: "invalid", reason: "test")
                    @parse
                    let a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    let a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.failedExpectation(
                            message: "Expected the first argument of `@parseSkip` to be an integer literal representing byte count.",
                        ),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func computedPropertyWithParse() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse
                    var a: Int {
                        get { 42 }
                        set { }
                    }
                }
                """#,
                expandedSource: """
                public struct Header {
                    var a: Int {
                        get { 42 }
                        set { }
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError.parseAccessorVariableDecl,
                        line: 4,
                        column: 9,
                    ),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func byteCountParseConvertInParse() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @parse(byteCount: 0xFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF)
                    var a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    var a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError
                            .failedExpectation(message: "byteCount should be convertible to Int."),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }

        @Test
        func byteCountParseConvertInSkip() {
            assertMacroExpansion(
                #"""
                @ParseStruct
                public struct Header {
                    @skip(byteCount: 0xFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, because: "test bad byte count")
                    @parse
                    var a: Int
                }
                """#,
                expandedSource: """
                public struct Header {
                    var a: Int
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        diagnostic: ParseStructMacroError
                            .failedExpectation(message: "byteCount should be convertible to Int."),
                        line: 3,
                        column: 5,
                    ),
                    specificFieldParsingError(line: 3, column: 5),
                    parseStructTopError,
                ],
            )
        }
    }
}

// MARK: - Diagnostic

private nonisolated(unsafe) let parseStructTopError = DiagnosticSpec(
    diagnostic: ParseStructMacroError.fatalError(message: "Parsing struct's fields has encountered an error."),
    line: 1,
    column: 1,
)

private func specificFieldParsingError(line: Int, column: Int) -> DiagnosticSpec {
    .init(
        diagnostic: ParseStructMacroError.fatalError(message: "Encountered errors during parsing field."),
        line: line,
        column: column,
    )
}

private nonisolated(unsafe) let noParseVarExist = DiagnosticSpec(
    diagnostic: ParseStructMacroError.emptyParse,
    line: 1,
    column: 1,
)
