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

/// Represents a grouped action for struct parsing
enum StructActionGroup {
    case parse(TokenSyntax, TypeSyntax, ParseMacroInfo)
    case skip(TokenSyntax, SkipMacroInfo)
    case maskGroup([(TokenSyntax, TypeSyntax, MaskMacroInfo)])
}

/// Computes action groups from struct variables, grouping consecutive @mask fields
func computeActionGroups(from variables: ParseStructField.ParseVariableMapping) -> [StructActionGroup] {
    var result: [StructActionGroup] = []
    var pendingMaskGroup: [(TokenSyntax, TypeSyntax, MaskMacroInfo)] = []

    func flushMaskGroup() {
        if !pendingMaskGroup.isEmpty {
            result.append(.maskGroup(pendingMaskGroup))
            pendingMaskGroup.removeAll()
        }
    }

    for (variableName, variableInfo) in variables {
        for action in variableInfo.parseActions {
            switch action {
            case let .parse(fieldParseInfo):
                flushMaskGroup()
                result.append(.parse(variableName, variableInfo.type, fieldParseInfo))
            case let .skip(skipInfo):
                flushMaskGroup()
                result.append(.skip(variableName, skipInfo))
            case let .mask(maskInfo):
                pendingMaskGroup.append((variableName, variableInfo.type, maskInfo))
            }
        }
    }

    flushMaskGroup()
    return result
}

public struct ConstructStructParseMacro: ExtensionMacro {
    public static func expansion(
        of attributeNode: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            throw ParseStructMacroError.onlyStructsAreSupported
        }

        let accessorInfo = try extractAccessor(
            from: attributeNode,
            attachedTo: structDeclaration,
            in: context,
        )

        let structFieldInfo = ParseStructField(context: context)
        structFieldInfo.walk(structDeclaration)
        try structFieldInfo.validate(for: structDeclaration)

        let type = TypeSyntax(type)

        let extensionSyntax =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.parsableProtocol)") {
                try InitializerDeclSyntax(
                    "\(accessorInfo.parsingAccessor) init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
                ) {
                    // Group consecutive mask fields and process them together
                    // Pre-compute groups of actions
                    let actionGroups = computeActionGroups(from: structFieldInfo.variables)

                    for actionGroup in actionGroups {
                        switch actionGroup {
                        case let .parse(variableName, variableType, fieldParseInfo):
                            generateParseBlock(
                                variableName: variableName,
                                variableType: variableType,
                                fieldParseInfo: fieldParseInfo,
                                useSelf: true,
                            )
                        case let .skip(variableName, skipInfo):
                            generateSkipBlock(variableName: variableName, skipInfo: skipInfo)
                        case let .maskGroup(maskFields):
                            try generateMaskGroupBlock(maskGroup: maskFields, context: context)
                        }
                    }
                }
            }

        // Collect printer field info before the result builder
        var parseSkipMacroInfo: [PrintableFieldInfo] = []
        for (variableName, variableInfo) in structFieldInfo.variables {
            for parseAction in variableInfo.parseActions {
                switch parseAction {
                case let .parse(parseInfo):
                    parseSkipMacroInfo.append(
                        .init(
                            binding: variableName,
                            byteCount: parseInfo.byteCount.toExprSyntax()
                                .map { "\(raw: Constants.Swift.byteCountType)(\($0))" },
                            endianness: parseInfo.endianness,
                        ),
                    )
                case let .skip(skipInfo):
                    parseSkipMacroInfo.append(
                        .init(
                            binding: nil,
                            byteCount: "\(raw: Constants.Swift.byteCountType)(\(raw: skipInfo.byteCount))",
                            endianness: nil,
                        ),
                    )
                case .mask:
                    // TODO: Add proper printer support for mask fields
                    // For now, mask fields are not included in printer intel
                    continue
                }
            }
        }

        let printerExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.printableProtocol)") {
                try FunctionDeclSyntax("\(accessorInfo.printingAccessor) func printerIntel() throws -> PrinterIntel") {
                    let fields = ArrayExprSyntax(elements: generatePrintableFields(parseSkipMacroInfo))

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
