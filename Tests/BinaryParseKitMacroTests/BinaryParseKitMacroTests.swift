import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

private nonisolated(unsafe) let parseStructTopError = DiagnosticSpec(
    message: "Fatal error: Parsing struct's fields has encountered an error.",
    line: 1,
    column: 1,
    severity: .error,
)

private func specificFieldParsingError(line: Int, column: Int) -> DiagnosticSpec {
    .init(
        message: "Fatal error: Encountered errors during parsing field.",
        line: line,
        column: column,
        severity: .error,
    )
}

private nonisolated(unsafe) let noParseVarExist = DiagnosticSpec(
    message: "No variables with `@parse` attribute found in the struct. Ensure at least one variable is marked for parsing.",
    line: 1,
    column: 1,
    severity: .warning,
)

@Suite(.disabled(if: !shouldRunMacroTest, "macros are not supported and cannot be imported for testing"))
struct BinaryParseKitMacroTests {
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
                    @inline(__always) func __assertParsable<T: BinaryParseKit.Parsable>(_ type: T.Type) {
                    }
                    @inline(__always) func __assertSizedParsable<T: BinaryParseKit.SizedParsable>(_ type: T.Type) {
                    }
                    @inline(__always) func __assertEndianParsable<T: BinaryParseKit.EndianParsable>(_ type: T.Type) {
                    }
                    @inline(__always) func __assertEndianSizedParsable<T: BinaryParseKit.EndianSizedParsable>(_ type: T.Type) {
                    }
                    __assertEndianSizedParsable(Int.self)
                    self.a = try .init(parsing: &span, endianness: .big, byteCount: 1)
                    __assertEndianParsable(Int32.self)
                    self.b = try .init(parsing: &span, endianness: .little)
                    try span.seek(toRelativeOffset: 2)
                    try span.seek(toRelativeOffset: 4)
                    __assertEndianParsable(Float16.self)
                    self.d = try .init(parsing: &span, endianness: .big)
                    __assertParsable(CustomValue.self)
                    self.c = try .init(parsing: &span)
                    try span.seek(toRelativeOffset: 6)
                    __assertParsable(CustomValue.self)
                    self.e = try .init(parsing: &span)
                    __assertSizedParsable(CustomValue.self)
                    self.g = try .init(parsing: &span, byteCount: Int(self.b))
                    try span.seek(toRelativeOffset: 7)
                    __assertEndianSizedParsable(CustomValue.self)
                    self.f = try .init(parsing: &span, endianness: .little, byteCount: span.endPosition - span.startPosition)
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
                    message: "@ParseStruct only supports structs. Please use a struct declaration or other macros.",
                    line: 1,
                    column: 1,
                    severity: .error,
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
                    message: "@ParseStruct only supports structs. Please use a struct declaration or other macros.",
                    line: 1,
                    column: 1,
                    severity: .error,
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
                    message: "Variable declarations must have a type annotation to be parsed.",
                    line: 4,
                    column: 9,
                    severity: .error,
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
                    message: "The variable declaration must have a `@parse` attribute.",
                    line: 3,
                    column: 9,
                    severity: .error,
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
                    message: "Multiple or non-trailing `@parseRest` attributes are not allowed. Only one trailing `@parseRest` is permitted.",
                    line: 6,
                    column: 9,
                    severity: .error,
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
                    message: "Multiple or non-trailing `@parseRest` attributes are not allowed. Only one trailing `@parseRest` is permitted.",
                    line: 6,
                    column: 9,
                    severity: .error,
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
                    @inline(__always) func __assertParsable<T: BinaryParseKit.Parsable>(_ type: T.Type) {
                    }
                    @inline(__always) func __assertSizedParsable<T: BinaryParseKit.SizedParsable>(_ type: T.Type) {
                    }
                    @inline(__always) func __assertEndianParsable<T: BinaryParseKit.EndianParsable>(_ type: T.Type) {
                    }
                    @inline(__always) func __assertEndianSizedParsable<T: BinaryParseKit.EndianSizedParsable>(_ type: T.Type) {
                    }
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
                    message: "Variable declaration must be an identifier definition.",
                    line: 4,
                    column: 9,
                    severity: .error,
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
                    message: "Unknown argument in `@parse`: 'unknownArgument: 42'. Please check the attribute syntax.",
                    line: 3,
                    column: 12,
                    severity: .error,
                ),
                DiagnosticSpec(
                    message: "Fatal error: @parse argument validation failed.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "Fatal error: Both `byteCountOf` and `byteCount` cannot be specified at the same time.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "Failed expectation: byteCount should be an integer literal.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "Failed expectation: byteCountOf should be a KeyPath lietarl expression.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "Failed expectation: Expected a labeled expression list for `@parseSkip` attribute, but found none.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "Fatal error: Expected exactly two arguments for `@parseSkip` attribute, but found 1.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "Failed expectation: Expected the first argument of `@parseSkip` to be an integer literal representing byte count.",
                    line: 3,
                    column: 5,
                    severity: .error,
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
                    message: "The variable declaration with accessor(s) (`get` and `set`) cannot be parsed.",
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
                    message: "Failed expectation: byteCount should be convertible to Int.",
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
                    message: "Failed expectation: byteCount should be convertible to Int.",
                    line: 3,
                    column: 5,
                ),
                specificFieldParsingError(line: 3, column: 5),
                parseStructTopError,
            ],
        )
    }
}
