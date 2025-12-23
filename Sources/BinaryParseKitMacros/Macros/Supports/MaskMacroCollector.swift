//
//  MaskMacroCollector.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Collects `@mask` annotated fields from a bitmask struct declaration.
class MaskMacroCollector: SyntaxVisitor {
    private let context: any MacroExpansionContext

    /// The collected mask field information.
    private(set) var maskInfoCollection: [MaskMacroInfo] = []

    /// Accumulated errors during collection.
    private(set) var errors: [Diagnostic] = []

    /// Current variable declaration being processed.
    private var currentVariableDecl: VariableDeclSyntax?

    /// Current mask attribute being processed.
    private var currentMaskAttribute: AttributeSyntax?

    init(context: some MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: - Visitor Methods

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Skip static declarations
        guard !node.isStaticDecl else {
            return .skipChildren
        }

        currentVariableDecl = node
        currentMaskAttribute = nil

        // Look for @mask attribute
        for attribute in node.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "mask"
            else {
                continue
            }
            currentMaskAttribute = attr
            break
        }

        return .visitChildren
    }

    override func visitPost(_: VariableDeclSyntax) {
        currentVariableDecl = nil
        currentMaskAttribute = nil
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        guard let variableDecl = currentVariableDecl else {
            return .skipChildren
        }

        // Skip computed properties
        if node.hasAccessor {
            return .skipChildren
        }

        // Get the field name
        guard let fieldName = node.identifierName else {
            errors.append(
                .init(
                    node: node,
                    message: ParseBitmaskMacroError.fatalError(message: "Expected identifier pattern"),
                ),
            )
            return .skipChildren
        }

        // Get the field type
        guard let fieldType = node.typeName else {
            errors.append(
                .init(
                    node: node,
                    message: ParseBitmaskMacroError.missingTypeAnnotation(fieldName: fieldName.text),
                ),
            )
            return .skipChildren
        }

        // Check for @mask attribute
        guard let maskAttribute = currentMaskAttribute else {
            errors.append(
                .init(
                    node: variableDecl,
                    message: ParseBitmaskMacroError.missingMaskAttribute(fieldName: fieldName.text),
                ),
            )
            return .skipChildren
        }

        // Parse the mask info
        do {
            let maskInfo = try MaskMacroInfo(
                from: maskAttribute,
                name: fieldName,
                type: fieldType,
                source: Syntax(variableDecl),
            )
            maskInfoCollection.append(maskInfo)
        } catch {
            errors.append(.init(node: maskAttribute, message: error))
        }

        return .skipChildren
    }

    // MARK: - Validation

    /// Validates the collected mask info and throws if there are errors.
    func validate() throws(ParseBitmaskMacroError) {
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw .fatalError(message: "Encountered errors while collecting @mask fields.")
        }
    }

    /// Computes the start bit positions for all fields and returns the total bit count.
    ///
    /// - Returns: The total bit count of all fields.
    /// - Throws: `ParseBitmaskMacroError` if any field's bit count cannot be determined.
    func computeBitPositions() throws(ParseBitmaskMacroError) -> Int {
        var currentBit = 0

        for index in maskInfoCollection.indices {
            maskInfoCollection[index].startBit = currentBit

            guard let fieldBitCount = maskInfoCollection[index].bitCount.value else {
                // Need to infer bit count from type - this will be handled at code generation
                // For now, we can't compute positions if any field has inferred bit count
                throw .cannotInferFieldBitCount(
                    fieldName: maskInfoCollection[index].name.text,
                    typeName: maskInfoCollection[index].type.description,
                )
            }

            currentBit += fieldBitCount
        }

        return currentBit
    }

    /// Returns the total bit count from explicitly specified fields.
    /// Returns `nil` if any field has an inferred bit count.
    var totalExplicitBitCount: Int? {
        var total = 0
        for info in maskInfoCollection {
            guard let bitCount = info.bitCount.value else {
                return nil
            }
            total += bitCount
        }
        return total
    }
}
