//
//  ParseActionGroup.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//
import OrderedCollections
import SwiftSyntax
import SwiftSyntaxMacros

/// Represents a grouped action for struct parsing
enum ParseActionGroup {
    struct ParseAction {
        let variableName: TokenSyntax
        let variableType: TypeSyntax
        let parseInfo: ParseMacroInfo
    }

    struct SkipAction {
        let variableName: TokenSyntax
        let skipInfo: SkipMacroInfo
    }

    struct MaskGroupAction {
        let variableName: TokenSyntax
        let variableType: TypeSyntax
        let maskInfo: MaskMacroInfo
    }

    case parse(ParseAction)
    case skip(SkipAction)
    case maskGroup([MaskGroupAction])
}

/// Computes action groups from enum parse actions, grouping consecutive @mask fields
func computeEnumActionGroups(
    from parseActions: [EnumParseAction],
    caseElementName: TokenSyntax,
    type: some TypeSyntaxProtocol,
    context: some MacroExpansionContext,
) -> ([ParseActionGroup], OrderedDictionary<TokenSyntax, TokenSyntax?>) {
    var result: [ParseActionGroup] = []
    var arguments: OrderedDictionary<TokenSyntax, TokenSyntax?> = [:]
    var pendingMaskGroup: [ParseActionGroup.MaskGroupAction] = []

    func flushMaskGroup() {
        if !pendingMaskGroup.isEmpty {
            result.append(.maskGroup(pendingMaskGroup))
            pendingMaskGroup.removeAll()
        }
    }

    for parseAction in parseActions {
        switch parseAction {
        case let .parse(caseArgParseInfo):
            flushMaskGroup()
            let variableName = caseArgParseInfo.firstName ?? context.makeUniqueName(
                "\(type)_\(caseElementName.text)_\(arguments.count)".escapeForVariableName(),
            )
            result.append(.parse(.init(
                variableName: variableName,
                variableType: caseArgParseInfo.type,
                parseInfo: caseArgParseInfo.parseInfo,
            )))
            arguments[variableName] = caseArgParseInfo.firstName
        case let .skip(skipInfo):
            flushMaskGroup()
            result.append(.skip(.init(variableName: caseElementName, skipInfo: skipInfo)))
        case let .mask(maskArgInfo):
            let variableName = maskArgInfo.firstName ?? context.makeUniqueName(
                "\(type)_\(caseElementName.text)_\(arguments.count)".escapeForVariableName(),
            )
            pendingMaskGroup.append(.init(
                variableName: variableName,
                variableType: maskArgInfo.type,
                maskInfo: maskArgInfo.maskInfo,
            ))
            arguments[variableName] = maskArgInfo.firstName
        }
    }

    flushMaskGroup()
    return (result, arguments)
}

/// Computes action groups from struct variables, grouping consecutive @mask fields
func computeStructActionGroups(from variables: ParseStructField.ParseVariableMapping) -> [ParseActionGroup] {
    var result: [ParseActionGroup] = []
    var pendingMaskGroup: [ParseActionGroup.MaskGroupAction] = []

    func flushMaskGroup() {
        if !pendingMaskGroup.isEmpty {
            result.append(.maskGroup(pendingMaskGroup))
            pendingMaskGroup.removeAll()
        }
    }

    for (variableName, variableInfo) in variables {
        for action in variableInfo.parseActions {
            switch action {
            case let .parse(fieldParseInfo):
                flushMaskGroup()
                result.append(
                    .parse(
                        .init(
                            variableName: variableName,
                            variableType: variableInfo.type,
                            parseInfo: fieldParseInfo,
                        ),
                    ),
                )
            case let .skip(skipInfo):
                flushMaskGroup()
                result.append(
                    .skip(
                        .init(
                            variableName: variableName,
                            skipInfo: skipInfo,
                        ),
                    ),
                )
            case let .mask(maskInfo):
                pendingMaskGroup.append(
                    .init(
                        variableName: variableName,
                        variableType: variableInfo.type,
                        maskInfo: maskInfo,
                    ),
                )
            }
        }
    }

    flushMaskGroup()
    return result
}
