//
//  ConstructParseStructMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//
import BinaryParsing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConstructStructParseMacro: ExtensionMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            let error = ParseStructMacroError.onlyStructsAreSupported
            throw error
        }

        let modifiers = declaration.modifiers

        let structFieldInfo = ParseStructField(context: context)
        structFieldInfo.walk(structDeclaration)
        try structFieldInfo.validate(for: structDeclaration)

        let type = TypeSyntax(type)

        let (parsableFnName, parsableFn) = try generateAssertParsable()
        let (sizedParsableFnName, sizedParsableFn) = try generateAssertSizedParsable()
        let (endianParsableFnName, endianParsableFn) = try generateAssertEndianParsable()
        let (endianSizedParsableFnName, endianSizedParsableFn) = try generateAssertEndianSizedParsable()

        @CodeBlockItemListBuilder
        func generateParseBlock(
            variableName: String,
            variableType: String,
            fieldParseInfo: StructFieldParseInfo,
        ) -> CodeBlockItemListSyntax {
            let byteCount: ExprSyntax? = switch fieldParseInfo.byteCount {
            case let .fixed(count):
                ExprSyntax("\(raw: count)")
            case .variable:
                ExprSyntax("span.endPosition - span.startPosition")
            case .unspecified:
                nil
            case let .ofVariable(expr):
                ExprSyntax("Int(\(expr))")
            }
            let endianness = fieldParseInfo.endianness

            switch (endianness, byteCount) {
            case let (endianness?, size?):
                #"""
                // Parse `\#(raw: variableName)` of type \#(raw: variableType) with endianness and byte count
                \#(endianSizedParsableFnName)(\#(raw: variableType).self)
                """#
                #"""
                self.\#(raw: variableName) = try .init(parsing: &span, endianness: \#(endianness), byteCount: \#(size))
                """#
            case (let endianness?, nil):
                #"""
                // Parse `\#(raw: variableName)` of type \#(raw: variableType) with endianness
                \#(endianParsableFnName)(\#(raw: variableType).self)
                """#
                #"""
                self.\#(raw: variableName) = try .init(parsing: &span, endianness: \#(endianness))
                """#
            case (nil, let size?):
                #"""
                // Parse `\#(raw: variableName)` of type \#(raw: variableType) with byte count
                \#(sizedParsableFnName)(\#(raw: variableType).self)
                """#
                #"""
                self.\#(raw: variableName) = try .init(parsing: &span, byteCount: \#(size))
                """#
            case (nil, nil):
                #"""
                // Parse `\#(raw: variableName)` of type \#(raw: variableType)
                \#(parsableFnName)(\#(raw: variableType).self)
                """#
                #"""
                self.\#(raw: variableName) = try .init(parsing: &span)
                """#
            }
        }

        @CodeBlockItemListBuilder
        func generateSkipBlock(variableName: String, skipInfo: ParseSkipInfo) -> CodeBlockItemListSyntax {
            let byteCount = skipInfo.byteCount
            let reason = skipInfo.reason
            #"""
            // Skip \#(raw: byteCount) because of \#(reason), before parsing `\#(raw: variableName)`
            try span.seek(toRelativeOffset: \#(raw: byteCount))
            """#
        }

        let extensionSyntax = try ExtensionDeclSyntax("extension \(type): \(raw: Constants.parsableProtocol)") {
            try InitializerDeclSyntax(
                "\(modifiers)init(parsing span: inout BinaryParsing.ParserSpan) throws(BinaryParsing.ThrownParsingError)",
            ) {
                parsableFn
                sizedParsableFn
                endianParsableFn
                endianSizedParsableFn

                for (variableName, variableInfo) in structFieldInfo.variables {
                    for action in variableInfo.parseActions {
                        switch action {
                        case let .parse(fieldParseInfo):
                            generateParseBlock(
                                variableName: variableName,
                                variableType: variableInfo.type,
                                fieldParseInfo: fieldParseInfo,
                            )
                        case let .skip(skipInfo):
                            generateSkipBlock(variableName: variableName, skipInfo: skipInfo)
                        }
                    }
                }
            }
        }

        return [extensionSyntax]
    }
}
