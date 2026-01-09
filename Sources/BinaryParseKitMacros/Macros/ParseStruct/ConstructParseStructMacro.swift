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

        let structFieldInfo = try ParseStructField(context: context).scrape(structDeclaration)

        let type = TypeSyntax(type)

        // Group consecutive mask fields and process them together
        // Pre-compute groups of actions
        let actionGroups = computeStructActionGroups(from: structFieldInfo.variables)

        let extensionSyntax =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.parsableProtocol)") {
                try InitializerDeclSyntax(
                    "\(accessorInfo.parsingAccessor) init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
                ) {
                    for actionGroup in actionGroups {
                        switch actionGroup {
                        case let .parse(parseInfo):
                            generateParseBlock(
                                variableName: parseInfo.variableName,
                                variableType: parseInfo.variableType,
                                fieldParseInfo: parseInfo.parseInfo,
                                useSelf: true,
                            )
                        case let .skip(skipInfo):
                            generateSkipBlock(variableName: skipInfo.variableName, skipInfo: skipInfo.skipInfo)
                        case let .maskGroup(maskFields):
                            try generateMaskGroupBlock(
                                maskActions: maskFields,
                                bitEndian: accessorInfo.bitEndian,
                                context: context,
                            )
                        }
                    }
                }
            }

        let printerExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.printableProtocol)") {
                try FunctionDeclSyntax("\(accessorInfo.printingAccessor) func printerIntel() throws -> PrinterIntel") {
                    var printingInfo: [PrintableFieldInfo] = []
                    for parseAction in actionGroups {
                        switch parseAction {
                        case let .parse(parseInfo):
                            // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                            let _ = printingInfo.append(
                                .init(
                                    content: .binding(fieldName: parseInfo.variableName),
                                    byteCount: parseInfo.parseInfo.byteCount.toExprSyntax()
                                        .map { "\(raw: Constants.Swift.byteCountType)(\($0))" },
                                    endianness: parseInfo.parseInfo.endianness,
                                ),
                            )
                        case let .skip(skipInfo):
                            // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                            let _ = printingInfo.append(
                                .init(
                                    content: .skip,
                                    byteCount: "\(raw: Constants.Swift.byteCountType)(\(raw: skipInfo.skipInfo.byteCount))",
                                    endianness: nil,
                                ),
                            )
                        case let .maskGroup(masks):
                            // Mask fields now conform to Printable via RawBitsConvertible
                            // Include them in printer intel with nil byte count (the bitmask intel
                            // will handle the proper bit-level representation)
                            let maskResult = context.makeUniqueName("__maskBits")

                            let bitCountExtractExprs = masks
                                .map { mask -> ExprSyntax in
                                    "\(raw: Constants.UtilityFunctions.toRawBits)(\(mask.variableName), bitCount: \(mask.maskInfo.bitCount.expr(of: mask.variableType)))"
                                }

                            let combinedExpr: ExprSyntax = if let firstExpr = bitCountExtractExprs.first {
                                bitCountExtractExprs.dropFirst().reduce("try \(firstExpr)") { partialResult, nextExpr in
                                    "\(partialResult).appending(\(nextExpr))"
                                }
                            } else {
                                "RawBits()"
                            }

                            """
                            // bits from \(raw: masks.map(\.variableName.text).joined(separator: ", "))
                            let \(maskResult) = \(combinedExpr)
                            """

                            // swiftformat:disable:next redundantLet swiftlint:disable:next redundant_discardable_let
                            let _ = printingInfo.append(
                                .init(
                                    content: .bits(variableName: maskResult),
                                    byteCount: nil,
                                    endianness: nil,
                                ),
                            )
                        }
                    }

                    let fields = ArrayExprSyntax(elements: generatePrintableFields(printingInfo))

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
