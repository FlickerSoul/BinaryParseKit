//
//  ParseEnumField.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

class ParseEnumCase<C: MacroExpansionContext>: SyntaxVisitor {
    private let context: C

    private var workEnum: EnumDeclSyntax?
    private var currentParseMacroVisitor: StructFieldVisitor<C>?
    private var currentCaseElement: EnumCaseElementSyntax?
    private var caseParseInfo: [EnumCaseParseInfo] = []
    private(set) var parsedInfo: EnumParseInfo?

    private var errors: [Diagnostic] = []

    init(context: C) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        guard workEnum == nil else {
            return .skipChildren
        }

        workEnum = node
        return .visitChildren
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        // has multiple declaration in the same `case`, reject
        guard node.elements.count <= 1 else {
            errors.append(.init(node: node, message: ParseEnumMacroError.onlyOneEnumDeclarationForEachCase))
            return .skipChildren
        }

        return .visitChildren
    }

    override func visit(_ node: AttributeListSyntax) -> SyntaxVisitorContinueKind {
        currentParseMacroVisitor = StructFieldVisitor(context: context)
        currentParseMacroVisitor?.walk(node)
        do {
            try currentParseMacroVisitor?.validate()
        } catch {
            errors.append(.init(node: node, message: error))
        }

        return .skipChildren
    }

    override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
        currentCaseElement = node
        return .skipChildren
    }

    override func visitPost(_ node: EnumCaseDeclSyntax) {
        guard let workEnum else {
            errors.append(.init(
                node: node,
                message: ParseEnumMacroError.unexpectedError(description: "No enum to parse"),
            ))
            return
        }
        guard node.belongsTo(workEnum) else {
            return
        }
        guard let currentCaseElement else {
            errors.append(.init(
                node: node,
                message: ParseEnumMacroError.unexpectedError(description: "No enum case declaration"),
            ))
            return
        }

        guard let currentParseMacroVisitor else {
            errors.append(.init(
                node: node,
                message: ParseEnumMacroError.unexpectedError(description: "No parse macro visitor setup"),
            ))
            return
        }
        guard let matchAction = currentParseMacroVisitor.caseMatchAction else {
            errors.append(
                .init(
                    node: node,
                    message: ParseEnumMacroError.missingCaseMatchMacro,
                    // TODO: allow some enum cases to exist without match?
                    // FIXME: check cases that have parse but no match
                ),
            )
            return
        }

        let caseParameters = currentCaseElement.parameterClause?.parameters ?? []

        let enumParseActions: [EnumParseAction]
        do {
            enumParseActions = try currentParseMacroVisitor.parseActions.convertToEnumParseAction(with: caseParameters)
        } catch {
            errors.append(.init(node: caseParameters, message: error))
            return
        }

        if caseParseInfo.last?.matchAction.matchPolicy == .matchDefault {
            errors.append(
                .init(
                    node: node,
                    message: ParseEnumMacroError.defaultCaseMustBeLast,
                ),
            )
            return
        }

        caseParseInfo.append(
            .init(
                matchAction: matchAction,
                parseActions: enumParseActions,
                caseElementName: currentCaseElement.name,
            ),
        )
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        guard workEnum == node else {
            return
        }

        parsedInfo = .init(
            type: node.name,
            caseParseInfo: caseParseInfo,
        )
    }

    func validate() throws {
        for error in errors {
            context.diagnose(error)
        }

        if !errors.isEmpty {
            throw ParseEnumMacroError.unexpectedError(description: "Enum macro parsing encountered errors")
        }
    }
}

private extension EnumCaseDeclSyntax {
    func belongsTo(_ enumToCheck: EnumDeclSyntax) -> Bool {
        var pointer: Syntax? = Syntax(self)

        while let unwrappedPointer = pointer {
            if let pointerEnum = unwrappedPointer.as(EnumDeclSyntax.self) {
                return enumToCheck == pointerEnum
            }

            pointer = unwrappedPointer.parent
        }

        return false
    }
}

private extension [StructParseAction] {
    func convertToEnumParseAction(
        with parameters: EnumCaseParameterListSyntax,
    ) throws(ParseEnumMacroError) -> [EnumParseAction] {
        var result: [EnumParseAction] = []
        var parseActionIndex = 0

        func addAction(_ action: EnumParseAction) {
            result.append(action)
            parseActionIndex += 1
        }

        for parameter in parameters {
            while parseActionIndex < count, case let .skip(skipInfo) = self[parseActionIndex] {
                addAction(.skip(skipInfo))
            }

            guard parseActionIndex < count else {
                throw ParseEnumMacroError.parameterParseNumberNotMatch
            }

            guard case let .parse(parseInfo) = self[parseActionIndex] else {
                throw ParseEnumMacroError.unexpectedError(description: "countered skip action")
            }

            addAction(
                .parse(
                    .init(
                        parseInfo: parseInfo,
                        firstName: parameter.firstName,
                        type: parameter.type,
                    ),
                ),
            )
        }

        return result
    }
}
