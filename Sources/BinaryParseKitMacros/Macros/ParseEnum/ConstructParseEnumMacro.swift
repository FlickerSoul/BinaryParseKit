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
                            case let .parse(variableName, caseArgParseInfo):
                                generateParseBlock(
                                    variableName: variableName,
                                    variableType: caseArgParseInfo.type,
                                    fieldParseInfo: caseArgParseInfo.parseInfo,
                                    useSelf: false,
                                )
                            case let .skip(variableName, skipInfo):
                                generateSkipBlock(variableName: variableName, skipInfo: skipInfo)
                            case let .maskGroup(maskFields):
                                try generateEnumMaskGroupBlock(
                                    maskGroup: maskFields,
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
                            self = .\(caseParseInfo.caseElementName)(\(arguments.argumentList))
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

/// Represents an enum case argument for code generation
enum EnumCaseArgument {
    case parse(EnumCaseParameterParseInfo)
    case mask(EnumCaseParameterMaskInfo)

    var firstName: TokenSyntax? {
        switch self {
        case let .parse(info): info.firstName
        case let .mask(info): info.firstName
        }
    }
}

extension OrderedDictionary<TokenSyntax, EnumCaseArgument> {
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

/// Represents a grouped action for enum parsing
enum EnumActionGroup {
    case parse(TokenSyntax, EnumCaseParameterParseInfo)
    case skip(TokenSyntax, SkipMacroInfo)
    case maskGroup([(TokenSyntax, TypeSyntax, MaskMacroInfo)])
}

/// Computes action groups from enum parse actions, grouping consecutive @mask fields
func computeEnumActionGroups(
    from parseActions: [EnumParseAction],
    caseElementName: TokenSyntax,
    type: some TypeSyntaxProtocol,
    context: some MacroExpansionContext,
) -> ([EnumActionGroup], OrderedDictionary<TokenSyntax, EnumCaseArgument>) {
    var result: [EnumActionGroup] = []
    var arguments: OrderedDictionary<TokenSyntax, EnumCaseArgument> = [:]
    var pendingMaskGroup: [(TokenSyntax, TypeSyntax, MaskMacroInfo)] = []

    func flushMaskGroup() {
        if !pendingMaskGroup.isEmpty {
            result.append(.maskGroup(pendingMaskGroup))
            pendingMaskGroup.removeAll()
        }
    }

    for parseAction in parseActions {
        switch parseAction {
        case let .parse(caseArgParseInfo):
            flushMaskGroup()
            let variableName = if let argName = caseArgParseInfo.firstName {
                argName
            } else {
                context.makeUniqueName(
                    "\(type)_\(caseElementName.text)_\(arguments.count)"
                        .replacingOccurrences(of: ".", with: "_"),
                )
            }
            result.append(.parse(variableName, caseArgParseInfo))
            arguments[variableName] = .parse(caseArgParseInfo)
        case let .skip(skipInfo):
            flushMaskGroup()
            result.append(.skip(caseElementName, skipInfo))
        case let .mask(maskArgInfo):
            let variableName = if let argName = maskArgInfo.firstName {
                argName
            } else {
                context.makeUniqueName(
                    "\(type)_\(caseElementName.text)_\(arguments.count)"
                        .replacingOccurrences(of: ".", with: "_"),
                )
            }
            pendingMaskGroup.append((variableName, maskArgInfo.type, maskArgInfo.maskInfo))
            arguments[variableName] = .mask(maskArgInfo)
        }
    }

    flushMaskGroup()
    return (result, arguments)
}
