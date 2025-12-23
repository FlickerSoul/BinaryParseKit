//
//  ConstructParseEnumMacro.swift
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
        of attributeNode: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else {
            throw ParseEnumMacroError.onlyEnumsAreSupported
        }

        let accessorInfo = try extractAccessor(
            from: attributeNode,
            attachedTo: enumDeclaration,
            in: context,
        )

        let visitor = ParseEnumCase(context: context)
        visitor.walk(enumDeclaration)
        try visitor.validate()

        guard let parseInfo = visitor.parsedInfo else {
            throw ParseEnumMacroError.unexpectedError(description: "Macro analysis finished without info")
        }

        let parsingExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.parsableProtocol)") {
                try InitializerDeclSyntax(
                    "\(accessorInfo.parsingAccessor) init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
                ) {
                    for caseParseInfo in parseInfo.caseParseInfo {
                        // Generate the match condition based on match type
                        let matchCondition = try ConditionElementListSyntax {
                            if let matchLength = caseParseInfo.lengthToMatch() {
                                // Length-based matching: use __match(length:in:) with borrowing span
                                ExprSyntax(
                                    "\(raw: Constants.UtilityFunctions.matchLength)(length: \(matchLength), in: span)",
                                )
                            } else if let toBeMatched = caseParseInfo.bytesToMatch(of: type) {
                                // Byte-array-based matching: use __matchBytes with inout span
                                ExprSyntax("\(raw: Constants.UtilityFunctions.matchBytes)(\(toBeMatched), in: &span)")
                            } else {
                                // Otherwise, it's a failure on our side
                                throw ParseEnumMacroError.unexpectedError(
                                    description: "Failed to obtain matching bytes for \(caseParseInfo.caseElementName)",
                                )
                            }
                        }

                        try IfExprSyntax(
                            "if \(matchCondition)",
                        ) {
                            if caseParseInfo.matchAction.matchPolicy == .matchAndTake {
                                if let toBeMatched = caseParseInfo.bytesToMatch(of: type) {
                                    "try span.seek(toRelativeOffset: \(toBeMatched).count)"
                                } else {
                                    throw ParseEnumMacroError.unexpectedError(
                                        description: "Failed to obtain matching bytes for \(caseParseInfo.caseElementName) when taking",
                                    )
                                }
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
                try FunctionDeclSyntax("\(accessorInfo.printingAccessor) func printerIntel() throws -> PrinterIntel") {
                    try SwitchExprSyntax("switch self") {
                        for caseParseInfo in parseInfo.caseParseInfo {
                            var parseSkipMacroInfo: [PrintableFieldInfo] = []

                            let arguments = LabeledExprListSyntax {
                                for (index, parseAction) in caseParseInfo.parseActions.enumerated() {
                                    switch parseAction {
                                    case let .parse(enumCaseParameterParseInfo):
                                        let argumentBindingToken = context.makeUniqueName(
                                            "\(caseParseInfo.caseElementName)_\(enumCaseParameterParseInfo.firstName ?? "index_\(raw: index)")",
                                        )
                                        // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                                        let _ = parseSkipMacroInfo.append(
                                            .init(
                                                binding: argumentBindingToken,
                                                byteCount: enumCaseParameterParseInfo.parseInfo
                                                    .byteCount
                                                    .toExprSyntax()
                                                    .map { "\(raw: Constants.Swift.byteCountType)(\($0))" },
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
                                            .init(
                                                binding: nil,
                                                byteCount: "\(raw: Constants.Swift.byteCountType)(\(raw: skipMacroInfo.byteCount))",
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

                            let caseCodeBlock = try CodeBlockItemListSyntax {
                                let bytesTakenInMatching = context.makeUniqueName("bytesTakenInMatching")

                                if caseParseInfo.matchAction.isLengthMatch {
                                    // For length-based matching, use empty bytes array (similar to matchDefault)
                                    "let \(bytesTakenInMatching): [UInt8] = []"
                                } else if let bytesToMatch = caseParseInfo.bytesToMatch(of: type) {
                                    "let \(bytesTakenInMatching): [UInt8] = \(bytesToMatch)"
                                } else {
                                    throw ParseEnumMacroError.unexpectedError(
                                        description: "Failed to obtain matching bytes for \(caseParseInfo.caseElementName)",
                                    )
                                }

                                let matchPolicy = caseParseInfo.matchAction.matchPolicy

                                let fields = ArrayExprSyntax(elements: generatePrintableFields(parseSkipMacroInfo))

                                #"""
                                return .enum(
                                    .init(
                                        bytes: \#(bytesTakenInMatching),
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
