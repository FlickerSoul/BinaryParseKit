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
        let fieldVisitor = try MaskMacroVisitor(context: context).scrape(structDeclaration)

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
                    "\(accessorInfo.parsingAccessor) init(bits: borrowing BinaryParseKit.RawBitsSpan) throws",
                ) {
                    "var bitPosition = 0"

                    for fieldInfo in fieldVisitor.fields.values {
                        let bitCountExpr: ExprSyntax = switch fieldInfo.maskInfo.bitCount {
                        case let .specified(count):
                            count.expr
                        case .inferred:
                            "(\(fieldInfo.type)).bitCount"
                        }

                        switch fieldInfo.maskInfo.bitCount {
                        case .specified:
                            """
                            // Parse `\(fieldInfo.name)` of type `\(fieldInfo
                                .type)` with specified bit count \(bitCountExpr)
                            \(raw: Constants.UtilityFunctions.assertExpressibleByRawBits)((\(fieldInfo.type)).self)
                            """
                        case .inferred:
                            """
                            // Parse `\(fieldInfo.name)` of type `\(fieldInfo.type)` with inferred bit count
                            \(raw: Constants.UtilityFunctions.assertBitmaskParsable)((\(fieldInfo.type)).self)
                            """
                        }

                        // Extract field bits from the span
                        """
                        do {
                            let fieldBitCount = \(bitCountExpr)
                            self.\(fieldInfo.name) = try \(raw: Constants.UtilityFunctions.maskParsing)(
                                from: bits,
                                fieldType: (\(fieldInfo.type)).self,
                                fieldRequestedBitCount: fieldBitCount,
                                at: bitPosition
                            )
                            bitPosition += fieldBitCount
                        }
                        """
                    }
                }
            }

        let rawBitsConvertibleExtension =
            try ExtensionDeclSyntax(
                "extension \(type): \(raw: Constants.Protocols.rawBitsConvertibleProtocol)",
            ) {
                // toRawBits(bitCount:) method
                try FunctionDeclSyntax(
                    "\(accessorInfo.printingAccessor) func toRawBits(bitCount: Int) throws -> BinaryParseKit.RawBits",
                ) {
                    "var result = BinaryParseKit.RawBits()"

                    for fieldInfo in fieldVisitor.fields.values {
                        switch fieldInfo.maskInfo.bitCount {
                        case let .specified(count):
                            """
                            // Convert `\(fieldInfo.name)` of type `\(fieldInfo.type)` with specified bit count \(count
                                .expr)
                            result = result.appending(try \(raw: Constants.UtilityFunctions.toRawBits)(self.\(fieldInfo
                                .name), bitCount: \(count.expr)))
                            """
                        case .inferred:
                            """
                            // Convert `\(fieldInfo.name)` of type `\(fieldInfo.type)` with inferred bit count
                            \(raw: Constants.UtilityFunctions.assertRawBitsConvertible)((\(fieldInfo.type)).self)
                            """
                            "result = result.appending(try \(raw: Constants.UtilityFunctions.toRawBits)(self.\(fieldInfo.name), bitCount: (\(fieldInfo.type)).bitCount))"
                        }
                    }

                    "return result"
                }
            }

        let printableExtension =
            try ExtensionDeclSyntax(
                "extension \(type): \(raw: Constants.Protocols.printableProtocol)",
            ) {
                // printerIntel() method
                try FunctionDeclSyntax(
                    "\(accessorInfo.printingAccessor) func printerIntel() throws -> PrinterIntel",
                ) {
                    "let bits = try self.toRawBits(bitCount: Self.bitCount)"
                    "return .bitmask(.init(bits: bits))"
                }
            }

        return [bitmaskParsableExtension, rawBitsConvertibleExtension, printableExtension]
    }
}
