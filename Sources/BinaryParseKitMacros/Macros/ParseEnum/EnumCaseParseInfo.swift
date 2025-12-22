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
    let parseInfo: ParseMacroInfo
    let firstName: TokenSyntax?
    let type: TypeSyntax

    init(parseInfo: ParseMacroInfo, firstName: TokenSyntax?, type: TypeSyntax) {
        self.parseInfo = parseInfo
        self.firstName = firstName?.trimmed
        self.type = type.trimmed
    }
}

enum EnumParseAction {
    case parse(EnumCaseParameterParseInfo)
    case skip(SkipMacroInfo)
}

enum EnumMatchTarget {
    // @match() -> .bytes(nil)
    // @match(byte: byte) -> .byte([byte])
    // @match(bytes: bytes) -> .bytes(bytes)
    // @matchAndTake(byte: byte) -> .byte([byte])
    // @matchAndTake(bytes: bytes) -> .bytes(bytes)
    case bytes(ExprSyntax?)
    // @match(length: length) -> .length(length)
    case length(ExprSyntax)
}

struct EnumCaseMatchAction {
    let target: EnumMatchTarget
    let matchPolicy: EnumCaseMatchPolicy

    var matchBytes: ExprSyntax?? {
        if case let .bytes(bytes) = target {
            bytes
        } else {
            nil
        }
    }

    var matchLength: ExprSyntax? {
        if case let .length(length) = target {
            length
        } else {
            nil
        }
    }

    var isLengthMatch: Bool {
        if case .length = target {
            true
        } else {
            false
        }
    }

    var isByteMatch: Bool {
        if case .bytes = target {
            true
        } else {
            false
        }
    }

    static func match(bytes: ExprSyntax?) -> EnumCaseMatchAction {
        EnumCaseMatchAction(target: .bytes(bytes), matchPolicy: .match)
    }

    static func matchLength(_ length: ExprSyntax) -> EnumCaseMatchAction {
        EnumCaseMatchAction(target: .length(length), matchPolicy: .match)
    }

    static func matchDefault() -> EnumCaseMatchAction {
        EnumCaseMatchAction(target: .bytes("[]"), matchPolicy: .matchDefault)
    }

    static func matchAndTake(bytes: ExprSyntax?) -> EnumCaseMatchAction {
        EnumCaseMatchAction(target: .bytes(bytes), matchPolicy: .matchAndTake)
    }

    static func parseMatch(from attribute: AttributeSyntax) throws(ParseEnumMacroError) -> EnumCaseMatchAction {
        let arguments = attribute.arguments?.as(LabeledExprListSyntax.self)

        // Check if this is @match(length:)
        if let args = arguments,
           let firstArg = args.first,
           firstArg.label?.text == "length" {
            return .matchLength(firstArg.expression)
        }

        // Otherwise, parse as byte-based match
        let bytes = try parseBytesArgument(in: arguments, at: 0)
        return .match(bytes: bytes)
    }

    static func parseMatchDefault(from _: AttributeSyntax) -> EnumCaseMatchAction {
        .matchDefault()
    }

    static func parseMatchAndTake(from attribute: AttributeSyntax) throws(ParseEnumMacroError) -> EnumCaseMatchAction {
        let arguments = attribute.arguments?.as(LabeledExprListSyntax.self)
        let bytes = try parseBytesArgument(in: arguments, at: 0)

        return .matchAndTake(bytes: bytes)
    }

    private static func parseBytesArgument(
        in list: LabeledExprListSyntax?,
        at index: Int,
    ) throws(ParseEnumMacroError) -> ExprSyntax? {
        guard let list else {
            return nil
        }

        let byteCountArgument = list[list.index(at: index)]
        return if byteCountArgument.label?.text == "byte" {
            "[\(byteCountArgument.expression)]"
        } else if byteCountArgument.label?.text == "bytes" {
            byteCountArgument.expression
        } else {
            nil
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
    let source: Syntax

    init(
        matchAction: EnumCaseMatchAction,
        parseActions: [EnumParseAction],
        caseElementName: TokenSyntax,
        source: Syntax,
    ) {
        self.matchAction = matchAction
        self.parseActions = parseActions
        self.caseElementName = caseElementName.trimmed
        self.source = source
    }

    func bytesToMatch(of type: some TypeSyntaxProtocol) -> ExprSyntax? {
        matchAction.matchBytes.map { matchBytes in
            if let matchBytes {
                matchBytes
            } else {
                ExprSyntax(
                    "(\(type).\(caseElementName) as any \(raw: Constants.Protocols.matchableProtocol)).bytesToMatch()",
                )
            }
        }
    }

    func lengthToMatch() -> ExprSyntax? {
        matchAction.matchLength
    }
}

struct EnumParseInfo {
    let type: TokenSyntax
    let caseParseInfo: [EnumCaseParseInfo]

    init(type: TokenSyntax, caseParseInfo: [EnumCaseParseInfo]) {
        self.type = type.trimmed
        self.caseParseInfo = caseParseInfo
    }
}
