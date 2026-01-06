//
//  MaskMacroVisitor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//
import MacroToolkit
import OrderedCollections
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Visitor to collect @mask field information from a struct
class MaskMacroVisitor: SyntaxVisitor {
    struct FieldInfo {
        let name: TokenSyntax
        let type: TypeSyntax
        let maskInfo: MaskMacroInfo

        init(name: TokenSyntax, type: TypeSyntax, maskInfo: MaskMacroInfo) {
            self.name = name.trimmed
            self.type = type.trimmed
            self.maskInfo = maskInfo
        }
    }

    private let context: any MacroExpansionContext
    private(set) var fields: OrderedDictionary<TokenSyntax, FieldInfo> = [:]
    private(set) var errors: [Diagnostic] = []

    private var currentMaskInfo: MaskMacroInfo?

    init(context: any MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Skip static declarations
        guard !node.isStaticDecl else {
            return .skipChildren
        }

        guard currentMaskInfo == nil else {
            errors.append(
                .init(
                    node: node,
                    message: MaskMacroError
                        .fatalError(
                            message: "Multiple variable declarations in single `@mask` attribute is not supported.",
                        ),
                ),
            )
            return .skipChildren
        }

        currentMaskInfo = nil

        return .visitChildren
    }

    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self),
              identifier.name.text == "mask" else {
            return .skipChildren
        }

        currentMaskInfo = MaskMacroInfo.parse(from: node)

        return .skipChildren
    }

    override func visitPost(_: VariableDeclSyntax) {
        currentMaskInfo = nil
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        // Skip computed properties
        guard !node.hasAccessor else {
            return .skipChildren
        }

        guard let maskInfo = currentMaskInfo else {
            // Field without @mask - this is an error in @ParseBitmask
            errors.append(.init(node: node, message: ParseBitmaskMacroError.fieldMustHaveMaskAttribute))
            return .skipChildren
        }

        maskInfo.validate(in: &errors)

        do {
            try parsePatternBinding(node, maskInfo: maskInfo)
        } catch {
            errors.append(.init(node: node, message: error))
        }

        return .skipChildren
    }

    private func parsePatternBinding(_ node: PatternBindingSyntax, maskInfo: MaskMacroInfo) throws(MaskMacroError) {
        guard let variableName = node.identifierName?.trimmed else {
            throw .fatalError(message: "Expected identifier in variable declaration.")
        }

        guard let typeName = node.typeName else {
            throw .noTypeAnnotation
        }

        let fieldInfo = FieldInfo(
            name: variableName,
            type: typeName,
            maskInfo: maskInfo,
        )
        fields[variableName] = fieldInfo
    }

    func validate() throws(ParseBitmaskMacroError) {
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw .fatalError(message: "Errors encountered while parsing @mask fields.")
        }

        if fields.isEmpty {
            throw .noFieldsFound
        }
    }
}
