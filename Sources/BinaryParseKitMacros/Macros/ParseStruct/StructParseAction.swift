//
//  StructParseAction.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//
import SwiftSyntax

/// Information for @parseBitmask macro
struct ParseBitmaskInfo {
    let source: Syntax
}

enum StructParseAction {
    case parse(ParseMacroInfo)
    case skip(SkipMacroInfo)
    case parseBitmask(ParseBitmaskInfo)

    var source: Syntax {
        switch self {
        case let .parse(parse):
            parse.source
        case let .skip(skip):
            skip.source
        case let .parseBitmask(info):
            info.source
        }
    }
}
