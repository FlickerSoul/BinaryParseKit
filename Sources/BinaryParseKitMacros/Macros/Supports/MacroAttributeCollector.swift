//
//  MacroAttributeCollector.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

class MacroAttributeCollector: SyntaxVisitor {
    private enum MacroError: Error {
        case invalidParseAttribute
        case invalidParseRestAttribute
        case invalidSkipAttribute
        case absentParseAttribute
    }

    typealias ParseAction = StructParseAction
    typealias CaseMatchAction = EnumCaseMatchAction

    private let context: any MacroExpansionContext
    private(set) var parseActions: [ParseAction] = []
    private(set) var hasParseRest: Bool = false
    private(set) var hasParse: Bool = false
    private(set) var hasSkip: Bool = false
    private(set) var caseMatchAction: CaseMatchAction?

    private var errors: [Diagnostic] = []

    init(context: any MacroExpansionContext) {
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
                let parsed = try ParseMacroInfo(fromParse: attribute, in: context)
                parseActions.append(.parse(parsed))
                hasParse = true
            } catch {
                errors.append(.init(node: attribute, message: error))
            }
        } else if identifierToken == "parseRest" {
            parseActions.append(.parse(ParseMacroInfo(fromParseRest: attribute)))
            hasParse = true
            hasParseRest = true
        } else if identifierToken == "skip" {
            do {
                let skip = try SkipMacroInfo(from: attribute)
                parseActions.append(.skip(skip))
                hasSkip = true
            } catch {
                errors.append(.init(node: attribute, message: error))
            }
        } else if identifierToken == "match" {
            ensureMatchFirst(at: attribute)
            do {
                caseMatchAction = try .parseMatch(from: attribute)
            } catch {
                errors.append(.init(node: attribute, message: error))
            }
        } else if identifierToken == "matchAndTake" {
            ensureMatchFirst(at: attribute)
            do {
                caseMatchAction = try .parseMatchAndTake(from: attribute)
            } catch {
                errors.append(.init(node: attribute, message: error))
            }
        } else if identifierToken == "matchDefault" {
            ensureMatchFirst(at: attribute)
            caseMatchAction = .parseMatchDefault(from: attribute)
        }

        return .skipChildren
    }

    private func ensureMatchFirst(at attribute: AttributeSyntax) {
        if hasParse || hasSkip {
            errors.append(
                .init(
                    node: attribute,
                    message: ParseEnumMacroError.matchMustProceedParseAndSkip,
                ),
            )
        }
    }

    func validate() throws(ParseStructMacroError) {
        // TODO: more validations

        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }
            throw ParseStructMacroError.fatalError(message: "Encountered errors during parsing field.")
        }
    }

    func validate(errors: inout [Diagnostic]) {
        errors.append(contentsOf: self.errors)
    }
}
