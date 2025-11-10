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
    private var currentParseMacroVisitor: MacroAttributeCollector<C>?
    private var currentCaseElements: EnumCaseElementListSyntax?
    private var caseParseInfo: [EnumCaseParseInfo] = []
    private(set) var parsedInfo: EnumParseInfo?

    private var hasMatchDefault = false

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

    override func visit(_ node: AttributeListSyntax) -> SyntaxVisitorContinueKind {
        currentParseMacroVisitor = MacroAttributeCollector(context: context)
        currentParseMacroVisitor?.walk(node)
        currentParseMacroVisitor?.validate(errors: &errors)

        return .skipChildren
    }

    override func visit(_ node: EnumCaseElementListSyntax) -> SyntaxVisitorContinueKind {
        currentCaseElements = node
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
        guard let currentCaseElements, !currentCaseElements.isEmpty else {
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

        if matchAction.matchPolicy == .matchDefault {
            if hasMatchDefault {
                errors.append(
                    .init(
                        node: node,
                        message: ParseEnumMacroError.onlyOneMatchDefaultAllowed,
                    ),
                )
                return
            }

            hasMatchDefault = true
        } else {
            if hasMatchDefault {
                errors.append(
                    .init(
                        node: node,
                        message: ParseEnumMacroError.defaultCaseMustBeLast,
                    ),
                )
            }
        }

        for currentCaseElement in currentCaseElements {
            let enumParseActions = currentParseMacroVisitor.parseActions.convertToEnumParseAction(
                with: currentCaseElement,
                errors: &errors,
            )

            caseParseInfo.append(
                .init(
                    matchAction: matchAction,
                    parseActions: enumParseActions,
                    caseElementName: currentCaseElement.name,
                ),
            )
        }
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
        if !errors.isEmpty {
            for error in errors {
                context.diagnose(error)
            }

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
        with enumCase: EnumCaseElementSyntax,
        errors: inout [Diagnostic],
    ) -> [EnumParseAction] {
        let arguments = enumCase.parameterClause?.parameters ?? []

        var result: [EnumParseAction] = []
        var parseActionIndex = 0

        func addAction(_ action: EnumParseAction) {
            result.append(action)
            parseActionIndex += 1
        }

        for argument in arguments {
            while parseActionIndex < count, case let .skip(skipInfo) = self[parseActionIndex] {
                addAction(.skip(skipInfo))
            }

            guard parseActionIndex < count else {
                errors.append(
                    .init(
                        node: argument,
                        message: ParseEnumMacroError.caseArgumentsMoreThanMacros,
                    ),
                )
                break
            }

            switch self[parseActionIndex] {
            case let .parseStore(parseStoreInfo):
                addAction(.parseStore(parseStoreInfo))
            case let .parse(parseInfo):
                addAction(
                    .parse(
                        .init(
                            parseInfo: parseInfo,
                            firstName: argument.firstName,
                            type: argument.type,
                        ),
                    ),
                )
            case .skip:
                fatalError("countered skip action")
            }
        }

        if parseActionIndex != count {
            while parseActionIndex < count {
                let parseAction = self[parseActionIndex]

                errors.append(
                    .init(
                        node: parseAction.source,
                        message: ParseEnumMacroError.macrosMoreThanCaseArguments,
                        notes: [.init(
                            node: Syntax(enumCase),
                            message: MacrosMoreThanCaseArgumentsNote(enumCase: enumCase.description),
                        )],
                    ),
                )

                parseActionIndex += 1
            }
        }

        return result
    }
}

struct MacrosMoreThanCaseArgumentsNote: NoteMessage {
    let enumCase: String

    var message: String {
        "The enum case `\(enumCase)` has less associated values than parse/skip macros."
    }

    let noteID: SwiftDiagnostics.MessageID = .init(
        domain: "observer.universe.BinaryParseKit.MoreThanCaseArgumentsNote",
        id: "macrosMoreThanCaseArguments",
    )
}
