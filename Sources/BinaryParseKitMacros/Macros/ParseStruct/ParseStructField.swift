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

class ParseStructField<C: MacroExpansionContext>: SyntaxVisitor {
    struct VariableInfo {
        let type: String
        let parseActions: [StructParseAction]
    }

    typealias ParseVariableMapping = OrderedDictionary<String, VariableInfo>

    private let context: C

    private var hasParse: Bool = false
    private var structFieldVisitor: StructFieldVisitor<C>?
    private var existParseRestContent: Bool = false

    private(set) var variables: ParseVariableMapping = [:]

    private(set) var errors: [Diagnostic] = []

    init(context: C) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Skip static declarations
        guard !node.isStaticDecl else {
            return .skipChildren
        }

        hasParse = node.hasParseAttribute()
        let structFieldVisitor = StructFieldVisitor(context: context)
        structFieldVisitor.walk(node.attributes)

        do {
            try structFieldVisitor.validate(for: node.attributes)
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

        guard binding.hasTypeAnnotation else {
            throw .variableDeclNoTypeAnnotation
        }

        guard let variableName = binding.identifierName else {
            throw .notIdentifierDef
        }

        guard let typeName = binding.typeName else {
            throw .invalidTypeAnnotation
        }

        variables[variableName] = .init(type: typeName, parseActions: structFieldVisitor.actions)
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
