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

enum ParseBitmaskMacroError: Error, DiagnosticMessage {
    case onlyStructsAreSupported
    case fieldMustHaveMaskAttribute
    case noFieldsFound
    case fatalError(description: String)

    var message: String {
        switch self {
        case .onlyStructsAreSupported: "@ParseBitmask can only be applied to structs."
        case .fieldMustHaveMaskAttribute: "All fields in @ParseBitmask struct must have @mask attribute."
        case .noFieldsFound: "@ParseBitmask struct must have at least one field with @mask attribute."
        case let .fatalError(description: description): "Fatal error in ParseBitmask macro: \(description)"
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "observer.universe.BinaryParseKit.ParseBitmaskMacroError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        .error
    }
}

/// Visitor to collect @mask field information from a struct
private class ParseBitmaskField: SyntaxVisitor {
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
                            description: "Multiple variable declaration in single `@mask` attribute is not supported.",
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

        do {
            currentMaskInfo = try MaskMacroInfo.parse(from: node, fieldName: nil, fieldType: nil)
        } catch {
            errors.append(.init(node: node, message: error))
        }

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
            errors.append(.init(
                node: node,
                message: ParseBitmaskMacroError.fieldMustHaveMaskAttribute,
            ))
            return .skipChildren
        }

        guard let variableName = node.identifierName else {
            errors.append(
                .init(
                    node: node,
                    message: MaskMacroError.fatalError(description: "Expected identifier in variable declaration."),
                ),
            )
            return .skipChildren
        }

        guard let typeName = node.typeName else {
            errors.append(
                .init(
                    node: node,
                    message: MaskMacroError.noTypeAnnotation,
                ),
            )
            return .skipChildren
        }

        let fieldInfo = FieldInfo(
            name: variableName,
            type: typeName,
            maskInfo: MaskMacroInfo(
                bitCount: maskInfo.bitCount,
                fieldName: variableName,
                fieldType: typeName,
                source: maskInfo.source,
            ),
        )
        fields[variableName.trimmed] = fieldInfo

        return .skipChildren
    }

    func validate() throws(ParseBitmaskMacroError) {
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw .fatalError(description: "Errors encountered while parsing @mask fields.")
        }

        if fields.isEmpty {
            throw .noFieldsFound
        }
    }
}

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
        let fieldVisitor = ParseBitmaskField(context: context)
        fieldVisitor.walk(structDeclaration)
        try fieldVisitor.validate()

        // Build bitCount expression as sum of all field bit counts
        let bitCountExprs = fieldVisitor.fields.values.map { fieldInfo -> ExprSyntax in
            switch fieldInfo.maskInfo.bitCount {
            case let .specified(count):
                count.expr
            case .inferred:
                "(\(fieldInfo.type)).bitCount"
            }
        }

        let firstField = bitCountExprs.first
        let remainingFields = bitCountExprs.dropFirst()
        let totalBitCountExpr: ExprSyntax = if let firstField {
            remainingFields.reduce(firstField) { partialResult, next in
                "\(partialResult) + \(next)"
            }
        } else {
            "0"
        }

        let bitmaskParsableExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.bitmaskParsableProtocol)") {
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
