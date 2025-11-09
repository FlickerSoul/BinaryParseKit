//
//  ConsructParseEnumMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//

import BinaryParsing
import OrderedCollections
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConstructEnumParseMacro: ExtensionMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else {
            throw ParseEnumMacroError.onlyEnumsAreSupported
        }

        let visitor = ParseEnumCase(context: context)
        visitor.walk(enumDeclaration)
        try visitor.validate()

        guard let parseInfo = visitor.parsedInfo else {
            throw ParseEnumMacroError.unexpectedError(description: "Macro analysis finished without info")
        }

        let modifiers = declaration.modifiers

        let parsingExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.parsableProtocol)") {
                try InitializerDeclSyntax(
                    "\(modifiers)init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
                ) {
                    for caseParseInfo in parseInfo.caseParseInfo {
                        let toBeMatched = if let matchBytes = caseParseInfo.matchAction.matchBytes {
                            matchBytes
                        } else {
                            ExprSyntax(
                                "(\(type).\(caseParseInfo.caseElementName) as any MatchableRawRepresentable) .bytesToMatch()",
                            )
                        }

                        try IfExprSyntax(
                            "if \(raw: Constants.UtilityFunctions.matchBytes)(\(toBeMatched), in: &span)",
                        ) {
                            if caseParseInfo.matchAction.matchPolicy == .matchAndTake {
                                "try span.seek(toRelativeOffset: \(toBeMatched).count)"
                            }

                            var arguments: OrderedDictionary<TokenSyntax, EnumCaseParameterParseInfo> = [:]

                            for parseAction in caseParseInfo.parseActions {
                                switch parseAction {
                                case let .parse(caseArgParseInfo):
                                    let variableName = if let argName = caseArgParseInfo.firstName {
                                        argName
                                    } else {
                                        context.makeUniqueName(
                                            "\(type)_\(caseParseInfo.caseElementName.text)_\(arguments.count)"
                                                .replacingOccurrences(
                                                    of: ".",
                                                    with: "_",
                                                ),
                                        )
                                    }

                                    generateParseBlock(
                                        variableName: variableName,
                                        variableType: caseArgParseInfo.type,
                                        fieldParseInfo: caseArgParseInfo.parseInfo,
                                        useSelf: false,
                                    )

                                    // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                                    let _ =
                                        arguments[variableName] = caseArgParseInfo
                                case let .skip(parseSkipInfo):
                                    generateSkipBlock(
                                        variableName: caseParseInfo.caseElementName,
                                        skipInfo: parseSkipInfo,
                                    )
                                }
                            }

                            if arguments.isEmpty {
                                "self = .\(caseParseInfo.caseElementName)"
                            } else {
                                """
                                // construct `\(caseParseInfo.caseElementName)` with above associated values
                                self = .\(caseParseInfo.caseElementName)(\(arguments.argumentList))
                                """
                            }

                            "return"
                        }
                    }

                    #"throw \#(raw: Constants.BinaryParserKitError.failedToParse)("Failed to find a match for \#(type), at \(span.startPosition)")"#
                }
            }

        return [parsingExtension]
    }
}

extension OrderedDictionary<TokenSyntax, EnumCaseParameterParseInfo> {
    @LabeledExprListBuilder
    var argumentList: LabeledExprListSyntax {
        for (varName, varInfo) in self {
            LabeledExprSyntax(
                label: varInfo.firstName?.text,
                expression: DeclReferenceExprSyntax(baseName: varName),
            )
        }
    }
}
