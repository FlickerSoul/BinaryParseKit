//
//  StructFieldVisitor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

class StructFieldVisitor<C: MacroExpansionContext>: SyntaxVisitor {
    private enum MacroError: Error {
        case invalidParseAttribute
        case invalidParseRestAttribute
        case invalidSkipAttribute
        case absentParseAttribute
    }

    typealias Action = StructParseAction

    private let context: C
    private(set) var actions: [Action] = []
    private(set) var hasParseRest: Bool = false
    private(set) var hasParse: Bool = false

    private var errors: [Diagnostic] = []

    init(context: C) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ attribute: AttributeSyntax) -> SyntaxVisitorContinueKind {
        guard let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) else {
            context.addDiagnostics(from: MacroError.absentParseAttribute, node: attribute)
            return .skipChildren
        }

        let identifierToken = identifier.name.text

        if identifierToken == "parse" {
            do {
                let parsed = try StructFieldParseInfo(fromParse: attribute, in: context)
                actions.append(.parse(parsed))
                hasParse = true
            } catch {
                errors.append(.init(node: attribute, message: error))
            }
        } else if identifierToken == "parseRest" {
            actions.append(.parse(StructFieldParseInfo(fromParseRest: attribute)))
            hasParseRest = true
        } else if identifierToken == "skip" {
            do {
                let skip = try ParseSkipInfo(from: attribute)
                actions.append(.skip(skip))
            } catch {
                errors.append(.init(node: attribute, message: error))
            }
        }

        return .skipChildren
    }

    func validate(for _: SyntaxProtocol) throws(ParseStructMacroError) {
        // TODO: more validations

        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw ParseStructMacroError.fatalError(message: "Encountered errors during parsing field.")
        }
    }
}
