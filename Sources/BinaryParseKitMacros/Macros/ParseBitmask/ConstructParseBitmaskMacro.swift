//
//  ConstructParseBitmaskMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import Collections
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConstructParseBitmaskMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            throw ParseBitmaskMacroError.onlyStructsAreSupported
        }

        let type = type.trimmed

        let accessorInfo = try extractAccessor(
            from: node,
            attachedTo: declaration,
            in: context,
        )

        // Extract mask field info
        let fieldVisitor = MaskMacroVisitor(context: context)
        fieldVisitor.walk(structDeclaration)
        try fieldVisitor.validate()

        // Build bitCount expression as sum of all field bit counts
        let bitCountExprs = fieldVisitor.fields.values.map { fieldInfo -> ExprSyntax in
            fieldInfo.maskInfo.bitCount.expr(of: fieldInfo.type)
        }

        let firstField = bitCountExprs.first
        let remainingFields = bitCountExprs.dropFirst()
        let totalBitCountExpr: ExprSyntax = if let firstField {
            remainingFields.reduce(firstField) { partialResult, next in
                "\(partialResult) + \(next)"
            }
        } else {
            throw ParseBitmaskMacroError.noFieldsFound
        }

        let bitmaskParsableExtension =
            try ExtensionDeclSyntax(
                "extension \(type): \(raw: Constants.Protocols.expressibleByRawBitsProtocol), \(raw: Constants.Protocols.bitCountProvidingProtocol)",
            ) {
                // Static bitCount property
                try VariableDeclSyntax("\(accessorInfo.printingAccessor) static var bitCount: Int") {
                    totalBitCountExpr
                }

                // init(bits:) initializer
                try InitializerDeclSyntax(
                    "\(accessorInfo.parsingAccessor) init(bits: BinaryParseKit.RawBits) throws",
                ) {
                    "var offset = 0"

                    for fieldInfo in fieldVisitor.fields.values {
                        switch fieldInfo.maskInfo.bitCount {
                        case let .specified(count):
                            """
                            // Parse `\(fieldInfo.name)` of type `\(fieldInfo.type)` with specified bit count \(count
                                .expr)
                            \(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(fieldInfo.type)).self)
                            """
                            "self.\(fieldInfo.name) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(fieldInfo.type)).self, from: bits, offset: offset, count: \(count.expr))"
                            "offset += \(count.expr)"
                        case .inferred:
                            """
                            // Parse `\(fieldInfo.name)` of type `\(fieldInfo.type)` with inferred bit count
                            \(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(fieldInfo.type)).self)
                            """
                            "self.\(fieldInfo.name) = try \(raw: Constants.UtilityFunctions.parseFromBits)((\(fieldInfo.type)).self, from: bits, offset: offset, count: (\(fieldInfo.type)).bitCount)"
                            "offset += (\(fieldInfo.type)).bitCount"
                        }
                    }
                }
            }

        return [bitmaskParsableExtension]
    }
}
