//
//  EnumCaseParseInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/6/25.
//
import SwiftSyntax

enum EnumCaseMatchPolicy {
    /// Match bytes from parsing inputs
    case match
    /// Match and take bytes from parsing inputs
    case matchAndTake
    /// Match any cases that's not explicitly handled
    case matchDefault
}

/// Additional parsing information for each enum case
///
/// For instance, the following code
///
/// ```swift
/// @matchAndTake(byte: 0x01)
/// @parse()
/// @parse(endianness: .big)
/// case state(Bool, channel: UInt)
/// ```
///
/// will yield two ``EnumParseInfo`` items
/// where the first has `type` of `Bool` and no `name`, and the second has `type` of `UInt` and `name` of `channel`.
struct EnumCaseParameterParseInfo {
    let parseInfo: StructFieldParseInfo
    let firstName: TokenSyntax?
    let type: TypeSyntax
}

enum EnumParseAction {
    case parse(EnumCaseParameterParseInfo)
    case skip(ParseSkipInfo)
}

struct EnumCaseMatchAction {
    let matchBytes: ExprSyntax
    let matchPolicy: EnumCaseMatchPolicy

    static func match(bytes: ExprSyntax) -> EnumCaseMatchAction {
        EnumCaseMatchAction(matchBytes: bytes, matchPolicy: .match)
    }

    static func matchDefault() -> EnumCaseMatchAction {
        EnumCaseMatchAction(matchBytes: "[]", matchPolicy: .matchDefault)
    }

    static func matchAndTake(bytes: ExprSyntax) -> EnumCaseMatchAction {
        EnumCaseMatchAction(matchBytes: bytes, matchPolicy: .matchAndTake)
    }

    static func parseMatch(from attribute: AttributeSyntax) throws(ParseEnumMacroError) -> EnumCaseMatchAction {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            throw ParseEnumMacroError.unexpectedError(
                description: "Expected a labeled expression list for `@match` attribute, but found none.",
            )
        }

        let bytes = try parseBytesArgument(in: arguments, at: 0)

        return .match(bytes: bytes)
    }

    static func parseMatchDefault(from _: AttributeSyntax) -> EnumCaseMatchAction {
        .matchDefault()
    }

    static func parseMatchAndTake(from attribute: AttributeSyntax) throws(ParseEnumMacroError) -> EnumCaseMatchAction {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            throw ParseEnumMacroError.unexpectedError(
                description: "Expected a labeled expression list for `@matchAndTake` attribute, but found none.",
            )
        }

        let bytes = try parseBytesArgument(in: arguments, at: 0)

        return .match(bytes: bytes)
    }

    private static func parseBytesArgument(
        in list: LabeledExprListSyntax,
        at index: Int,
    ) throws(ParseEnumMacroError) -> ExprSyntax {
        let byteCountArgument = list[list.index(at: 0)]
        return if byteCountArgument.label?.text == "byte" {
            "[\(byteCountArgument.expression)]"
        } else if byteCountArgument.label?.text == "bytes" {
            byteCountArgument.expression
        } else {
            throw ParseEnumMacroError.unexpectedError(
                description: "Expected `byte` or `bytes` in \(index)th place of expression list in `@matchAndTake` attribute, but found none.",
            )
        }
    }
}

/// Parsing information for each enum case
///
/// For instance, the following code
///
/// ```swift
/// @matchAndTake(byte: 0x01)
/// @parse()
/// @skip(byteCount: 5, reason: "Not Sure")
/// @parse(endianness: .big)
/// case state(Bool, channel: UInt)
/// ```
///
/// will yield an ``EnumCaseParseInfo`` item, where `matchBytes` is `[0x01]`,
/// `matchPolicy` is `.matchAndTake`, and `parseActions` contains `[.parse, .skip, .parse]`,
/// and `caseElementName` is `state`.
struct EnumCaseParseInfo {
    let matchAction: EnumCaseMatchAction
    let parseActions: [EnumParseAction]
    let caseElementName: TokenSyntax
}

struct EnumParseInfo {
    let type: TokenSyntax
    let caseParseInfo: [EnumCaseParseInfo]
}
