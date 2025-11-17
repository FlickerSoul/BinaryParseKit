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
        let structFieldInfo = ParseStructField(context: context)
        structFieldInfo.walk(structDeclaration)
        try structFieldInfo.validate(for: structDeclaration)

        let type = TypeSyntax(type)
        let modifiers = declaration.modifiers

        let extensionSyntax =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.parsableProtocol)") {
                try InitializerDeclSyntax(
                    "\(modifiers)init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
                ) {
                    for (variableName, variableInfo) in structFieldInfo.variables {
                        for action in variableInfo.parseActions {
                            switch action {
                            case let .parse(fieldParseInfo):
                                generateParseBlock(
                                    variableName: variableName,
                                    variableType: variableInfo.type,
                                    fieldParseInfo: fieldParseInfo,
                                    useSelf: true,
                                )
                            case let .skip(skipInfo):
                                generateSkipBlock(variableName: variableName, skipInfo: skipInfo)
                            }
                        }
                    }
                }
            }

        let printerExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.printableProtocol)") {
                try FunctionDeclSyntax("\(modifiers)func parsedIntel() -> PrinterIntel") {
                    let fields = ArrayExprSyntax(
                        elements: ArrayElementListSyntax {
                            for (variableName, variableInfo) in structFieldInfo.variables {
                                var parseSkipMacroInfo: [PrintableFieldInfo] = []
                                for parseAction in variableInfo.parseActions {
                                    switch parseAction {
                                    case let .parse(parseInfo):
                                        // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                                        let _ = parseSkipMacroInfo.append(
                                            .init(
                                                binding: variableName,
                                                byteCount: parseInfo.byteCount.toExprSyntax()
                                                    .map { "\(raw: Constants.Swift.byteCountType)(\($0))" },
                                                endianness: parseInfo.endianness,
                                            ),
                                        )
                                    case let .skip(skipInfo):
                                        // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                                        let _ = parseSkipMacroInfo.append(
                                            .init(
                                                binding: nil,
                                                byteCount: "\(raw: Constants.Swift.byteCountType)(\(raw: skipInfo.byteCount))",
                                                endianness: nil,
                                            ),
                                        )
                                    }
                                }

                                generatePrintableFields(parseSkipMacroInfo)
                            }
                        },
                    )

                    #"""
                    return .struct(
                        .init(
                            fields: \#(fields)
                        )
                    )
                    """#
                }
            }

        return [extensionSyntax, printerExtension]
    }
}
