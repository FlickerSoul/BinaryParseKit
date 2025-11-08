//
//  BinaryParseKitEnumTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//

import Testing

@Suite(.disabled(if: !shouldRunMacroTest, "Skipping testing macros because it cannot be imported"))
struct TestParsingEnum {
    @Test
    func `parse regular enum`() {
        assertMacroExpansion(
            """
            @ParseEnum
            enum TestEnum {
                @match(byte: 0x08)
                case a

                @match(bytes: [0x01, 0x02])
                case b
            }
            """,
            expandedSource: """
            enum TestEnum {
                case a
                case b
            }

            extension TestEnum: BinaryParseKit.Parsable {
                init(parsing input: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError) {
                    if BinaryParseKit.__match([0x08], in: input) {
                        self = .a
                        return
                    }
                    if BinaryParseKit.__match([0x01, 0x02], in: input) {
                        self = .b
                        return
                    }
                }
            }
            """,
        )
    }

    @Test
    func `parse RawRepresentable enum by matching bytes`() {
        assertMacroExpansion(
            """
            @ParseEnum
            enum TestEnum: UInt8 {
                @match(byte: 0x08)
                case a

                @match(bytes: [0x01, 0x02])
                case b
            }
            """,
            expandedSource: """

            """,
        )
    }

    /// Test parsing RawRepresentable enum by matching raw value directly
    @Test
    func `parse RawRepresentable enum by matching types`() {
        assertMacroExpansion(
            """
            @ParseEnum
            enum TestEnum: UInt8 {
                @match
                case a

                @match
                case b
            }
            """,
            expandedSource: """

            """,
        )
    }

    @Test
    func `enum With Associated Value`() {
        assertMacroExpansion(
            """
            @ParseEnum
            enum TestEnum {
                @match(byte: 0x08)
                @parse(byteCount: 1)
                case a(SomeType)

                @match(bytes: [0x01, 0x02])
                case b(Int, value: SomeType)

                @match(byte: 0x09)
                case c(code: UInt8, value: SomeType)
            }
            """,
            expandedSource: """

            """,
        )
    }
}
