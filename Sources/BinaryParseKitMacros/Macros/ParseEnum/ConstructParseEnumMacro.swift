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

        let parsingExtension = try buildParsingExtension(
            type: type,
            parseInfo: parseInfo,
            accessorInfo: accessorInfo,
            context: context,
        )

        let printerExtension = try buildPrinterExtension(
            type: type,
            parseInfo: parseInfo,
            accessorInfo: accessorInfo,
            context: context,
        )

        return [parsingExtension, printerExtension]
    }

    private static func buildParsingExtension(
        type: some SwiftSyntax.TypeSyntaxProtocol,
        parseInfo: EnumParseInfo,
        accessorInfo: AccessorInfo,
        context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> ExtensionDeclSyntax {
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
                        } else if caseParseInfo.matchAction.target.isDefaultMatch {
                            // Default matching: always true
                            ExprSyntax("true")
                        } else {
                            // Otherwise, it's a failure on our side
                            throw ParseEnumMacroError.unexpectedError(
                                description: "Failed to obtain matching bytes for \(caseParseInfo.caseElementName)",
                            )
                        }
                    }

                    try IfExprSyntax("if \(matchCondition)") {
                        if caseParseInfo.matchAction.matchPolicy == .matchAndTake {
                            if let toBeMatched = caseParseInfo.bytesToMatch(of: type) {
                                "try span.seek(toRelativeOffset: \(toBeMatched).count)"
                            } else {
                                throw ParseEnumMacroError.unexpectedError(
                                    description: "Failed to obtain matching bytes for \(caseParseInfo.caseElementName) when taking",
                                )
                            }
                        }

                        // Pre-compute action groups and arguments outside the result builder
                        let (actionGroups, arguments) = computeEnumActionGroups(
                            from: caseParseInfo.parseActions,
                            caseElementName: caseParseInfo.caseElementName,
                            type: type,
                            context: context,
                        )

                        for actionGroup in actionGroups {
                            switch actionGroup {
                            case let .parse(parseInfo):
                                generateParseBlock(
                                    variableName: parseInfo.variableName,
                                    variableType: parseInfo.variableType,
                                    fieldParseInfo: parseInfo.parseInfo,
                                    useSelf: false,
                                )
                            case let .skip(skipInfo):
                                generateSkipBlock(variableName: skipInfo.variableName, skipInfo: skipInfo.skipInfo)
                            case let .maskGroup(maskActions):
                                try generateEnumMaskGroupBlock(
                                    maskActions: maskActions,
                                    caseElementName: caseParseInfo.caseElementName,
                                    context: context,
                                )
                            }
                        }

                        if arguments.isEmpty {
                            "self = .\(caseParseInfo.caseElementName)"
                        } else {
                            """
                            // construct `\(caseParseInfo.caseElementName)` with above associated values
                            self = .\(caseParseInfo.caseElementName)(\(arguments.asArgumentList))
                            """
                        }

                        "return"
                    }
                }

                #"throw \#(raw: Constants.BinaryParserKitError.failedToParse)("Failed to find a match for \#(type), at \(span.startPosition)")"#
            }
        }
    }

    private static func buildPrinterExtension(
        type: some SwiftSyntax.TypeSyntaxProtocol,
        parseInfo: EnumParseInfo,
        accessorInfo: AccessorInfo,
        context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> ExtensionDeclSyntax {
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
                                case let .mask(maskParseInfo):
                                    let argumentBindingToken = context.makeUniqueName(
                                        "\(caseParseInfo.caseElementName)_\(maskParseInfo.firstName ?? "index_\(raw: index)")",
                                    )
                                    // TODO: Add proper printer support for mask fields
                                    // For now, we just bind the variable without adding printer info
                                    LabeledExprSyntax(
                                        label: nil,
                                        expression: PatternExprSyntax(
                                            pattern: IdentifierPatternSyntax(
                                                identifier: argumentBindingToken,
                                            ),
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

                            if caseParseInfo.matchAction.target.isLengthMatch
                                || caseParseInfo.matchAction.target.isDefaultMatch {
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
    }
}

private extension OrderedDictionary<TokenSyntax, TokenSyntax?> {
    @LabeledExprListBuilder
    var asArgumentList: LabeledExprListSyntax {
        for (varName, varInfo) in self {
            LabeledExprSyntax(
                label: varInfo?.text,
                expression: DeclReferenceExprSyntax(baseName: varName),
            )
        }
    }
}
