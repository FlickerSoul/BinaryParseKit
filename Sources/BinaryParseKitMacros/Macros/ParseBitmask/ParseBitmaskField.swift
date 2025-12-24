//
//  ParseBitmaskField.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/24/25.
//

import Collections
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

class ParseBitmaskField: SyntaxVisitor {
    struct FieldInfo {
        let name: TokenSyntax
        let type: TypeSyntax
        let bitCount: MaskMacroInfo.BitCount

        init(name: TokenSyntax, type: TypeSyntax, bitCount: MaskMacroInfo.BitCount) {
            self.name = name.trimmed
            self.type = type.trimmed
            self.bitCount = bitCount
        }
    }

    typealias FieldMapping = OrderedDictionary<TokenSyntax, FieldInfo>

    private let context: any MacroExpansionContext

    private var currentMaskInfo: MaskMacroInfo?

    private(set) var fields: FieldMapping = [:]
    private(set) var errors: [Diagnostic] = []

    init(context: any MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Skip static declarations
        guard !node.isStaticDecl else {
            return .skipChildren
        }

        // Extract mask macro from attributes
        do {
            currentMaskInfo = try extractMaskInfo(from: node.attributes)
            return .visitChildren
        } catch {
            errors.append(.init(node: node.attributes, message: error))
            return .skipChildren
        }
    }

    override func visitPost(_: VariableDeclSyntax) {
        currentMaskInfo = nil
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        do {
            try parsePatternBinding(node)
        } catch {
            errors.append(.init(node: node, message: error))
        }

        return .skipChildren
    }

    private func extractMaskInfo(from attributes: AttributeListSyntax) throws(ParseBitmaskMacroError)
        -> MaskMacroInfo? {
        var maskInfo: MaskMacroInfo?

        for attribute in attributes {
            guard case let .attribute(attr) = attribute else { continue }

            let attrName = attr.attributeName.trimmedDescription

            if attrName == "mask" {
                if maskInfo != nil {
                    throw .multipleMaskAttributes
                }

                // Check if it has arguments
                if let arguments = attr.arguments, case let .argumentList(argList) = arguments {
                    // Look for bitCount argument
                    for arg in argList {
                        if arg.label?.text == "bitCount",
                           let intExpr = arg.expression.as(IntegerLiteralExprSyntax.self),
                           let bitCount = Int(intExpr.literal.text) {
                            maskInfo = MaskMacroInfo(
                                bitCount: .specified(bitCount),
                                name: TokenSyntax.identifier("mask"),
                                source: Syntax(attr),
                            )
                        }
                    }
                }

                // If no bitCount found, it's inferred
                if maskInfo == nil {
                    maskInfo = MaskMacroInfo(
                        bitCount: .inferred,
                        name: TokenSyntax.identifier("mask"),
                        source: Syntax(attr),
                    )
                }
            }
        }

        return maskInfo
    }

    private func parsePatternBinding(_ binding: PatternBindingSyntax) throws(ParseBitmaskMacroError) {
        if binding.hasAccessor {
            if currentMaskInfo != nil {
                throw .maskOnAccessorVariable
            } else {
                // Skip computed properties without mask
                return
            }
        }

        guard let maskInfo = currentMaskInfo else {
            throw .noMaskAttributeOnVariable
        }

        guard binding.hasTypeAnnotation else {
            throw .variableNoTypeAnnotation
        }

        guard let variableName = binding.identifierName else {
            throw .notIdentifierDef
        }

        guard let typeName = binding.typeName else {
            throw .invalidTypeAnnotation
        }

        fields[variableName.trimmed] = FieldInfo(
            name: variableName.trimmed,
            type: typeName,
            bitCount: maskInfo.bitCount,
        )
    }

    func validate(for node: some SwiftSyntax.SyntaxProtocol) throws(ParseBitmaskMacroError) {
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw .fatalError(message: "Parsing bitmask struct's fields has encountered an error.")
        }

        if fields.isEmpty {
            context.diagnose(.init(node: node, message: ParseBitmaskMacroError.emptyBitmask))
        }
    }
}
