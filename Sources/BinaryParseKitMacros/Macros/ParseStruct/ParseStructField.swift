//
//  ParseStructVisitor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//
import BinaryParseKitCommons
import Collections
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

class ParseStructField: SyntaxVisitor {
    struct VariableInfo {
        let type: TypeSyntax
        let parseActions: [StructParseAction]

        init(type: TypeSyntax, parseActions: [StructParseAction]) {
            self.type = type.trimmed
            self.parseActions = parseActions
        }
    }

    typealias ParseVariableMapping = OrderedDictionary<TokenSyntax, VariableInfo>

    private let context: any MacroExpansionContext

    private var hasParse: Bool = false
    private var structFieldVisitor: MacroAttributeCollector?
    private var existParseRestContent: Bool = false

    private(set) var variables: ParseVariableMapping = [:]

    private(set) var errors: [Diagnostic] = []

    init(context: any MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    @discardableResult
    func scrape(_ structSyntax: StructDeclSyntax) throws -> Self {
        walk(structSyntax.memberBlock.members)
        try validate(for: structSyntax)
        return self
    }

    override func visit(_: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Skip static declarations
        guard !node.isStaticDecl else {
            return .skipChildren
        }

        let structFieldVisitor = MacroAttributeCollector(context: context)
        structFieldVisitor.walk(node.attributes)
        hasParse = structFieldVisitor.hasParse || structFieldVisitor.hasMask

        do {
            try structFieldVisitor.validate()
            self.structFieldVisitor = structFieldVisitor
            return .visitChildren
        } catch {
            errors.append(.init(node: node.attributes, message: error))
            return .skipChildren
        }
    }

    override func visitPost(_: VariableDeclSyntax) {
        structFieldVisitor = nil
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        do {
            try parsePatternBinding(node)
        } catch {
            errors.append(.init(node: node, message: error))
        }

        return .skipChildren
    }

    private func parsePatternBinding(_ binding: PatternBindingSyntax) throws(ParseStructMacroError) {
        if binding.hasAccessor {
            if hasParse {
                throw .parseAccessorVariableDecl
            } else {
                print("skip unparsed accessor")
                return
            }
        }

        guard hasParse, let structFieldVisitor else {
            throw .noParseAttributeOnVariableDecl
        }

        if existParseRestContent {
            throw .multipleOrNonTrailingParseRest
        }

        if structFieldVisitor.hasParseRest {
            existParseRestContent = true
        }

        guard let variableName = binding.identifierName?.trimmed else {
            throw .notIdentifierDef
        }

        guard let typeName = binding.typeName else {
            throw .variableDeclNoTypeAnnotation
        }

        variables[variableName] = .init(type: typeName, parseActions: structFieldVisitor.parseActions)
    }

    func validate(for node: some SwiftSyntax.SyntaxProtocol) throws(ParseStructMacroError) {
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw .fatalError(message: "Parsing struct's fields has encountered an error.")
        }

        if variables.isEmpty {
            context.diagnose(.init(node: node, message: ParseStructMacroError.emptyParse))
        }
    }
}
