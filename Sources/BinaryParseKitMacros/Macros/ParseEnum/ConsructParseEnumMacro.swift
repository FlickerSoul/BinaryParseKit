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
                        let toBeMatched = caseParseInfo.bytesToMatch(of: type)

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

        let printerExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.printableProtocol)") {
                try FunctionDeclSyntax("\(modifiers)func parsedIntel() -> PrinterIntel") {
                    try SwitchExprSyntax("switch self") {
                        for caseParseInfo in parseInfo.caseParseInfo {
                            var parseSkipMacroInfo: [(
                                binding: TokenSyntax?,
                                byteCount: ExprSyntax?,
                                endianness: ExprSyntax?,
                            )] = []

                            let arguments = LabeledExprListSyntax {
                                for (index, parseAction) in caseParseInfo.parseActions.enumerated() {
                                    switch parseAction {
                                    case let .parse(enumCaseParameterParseInfo):
                                        let argumentBindingToken = context.makeUniqueName(
                                            "\(caseParseInfo.caseElementName)_\(enumCaseParameterParseInfo.firstName ?? "index_\(raw: index)")",
                                        )
                                        // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                                        let _ = parseSkipMacroInfo.append(
                                            (
                                                binding: argumentBindingToken,
                                                byteCount: enumCaseParameterParseInfo.parseInfo.byteCount
                                                    .toExprSyntax(),
                                                endianness: enumCaseParameterParseInfo.parseInfo.endianness,
                                            ),
                                        )

                                        LabeledExprSyntax(
                                            label: nil,
                                            expression: PatternExprSyntax(
                                                pattern: IdentifierPatternSyntax(
                                                    identifier: argumentBindingToken,
                                                ),
                                            ),
                                        )
                                    case let .skip(skipMacroInfo):
                                        // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                                        let _ = parseSkipMacroInfo.append(
                                            (
                                                binding: nil,
                                                byteCount: "\(raw: skipMacroInfo.byteCount)",
                                                endianness: nil,
                                            ),
                                        )
                                    }
                                }
                            }

                            let caseLabel = SwitchCaseLabelSyntax(
                                caseItems: SwitchCaseItemListSyntax {
                                    if !arguments.isEmpty {
                                        SwitchCaseItemSyntax(
                                            pattern: ValueBindingPatternSyntax(
                                                bindingSpecifier: .keyword(.let),
                                                pattern: ExpressionPatternSyntax(
                                                    expression: FunctionCallExprSyntax(
                                                        calledExpression: MemberAccessExprSyntax(name: caseParseInfo
                                                            .caseElementName),
                                                        leftParen: .leftParenToken(),
                                                        arguments: arguments,
                                                        rightParen: .rightParenToken(),
                                                    ),
                                                ),
                                            ),
                                        )
                                    } else {
                                        SwitchCaseItemSyntax(
                                            pattern: ExpressionPatternSyntax(
                                                expression: MemberAccessExprSyntax(
                                                    name: caseParseInfo.caseElementName,
                                                ),
                                            ),
                                        )
                                    }
                                })

                            let caseCodeBlock = CodeBlockItemListSyntax {
                                let toBeMatched = caseParseInfo.bytesToMatch(of: type)
                                let matchPolicy = caseParseInfo.matchAction.matchPolicy

                                let fields = ArrayExprSyntax(
                                    elements: ArrayElementListSyntax {
                                        for (binding, byteCount, endianness) in parseSkipMacroInfo {
                                            ArrayElementSyntax(
                                                expression:
                                                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(name: "init")) {
                                                    LabeledExprSyntax(
                                                        label: "byteCount",
                                                        expression: byteCount ?? ExprSyntax("nil"),
                                                    )
                                                    LabeledExprSyntax(
                                                        label: "bigEndian",
                                                        expression: endianness ?? ExprSyntax("nil"),
                                                    )
                                                    if let binding {
                                                        LabeledExprSyntax(
                                                            label: "intel",
                                                            expression: ExprSyntax(
                                                                "(\(binding) as any \(raw: Constants.Protocols.printableProtocol)).parsedIntel()",
                                                            ),
                                                        )
                                                    } else {
                                                        LabeledExprSyntax(
                                                            label: "intel",
                                                            expression: ExprSyntax(
                                                                ".skip(.init(byteCount: \(byteCount)))",
                                                            ),
                                                        )
                                                    }
                                                },
                                            )
                                        }
                                    })

                                #"""
                                return .enum(
                                    .init(
                                        enumCaseName: "\#(caseParseInfo.caseElementName)",
                                        bytes: \#(toBeMatched),
                                        parseType: .\#(raw: matchPolicy),
                                        fields: \#(fields),
                                    )
                                )
                                """#
                            }

                            SwitchCaseSyntax(
                                label: .case(caseLabel),
                                statements: caseCodeBlock,
                            )
                        }
                    }
                }
            }

        return [parsingExtension, printerExtension]
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
