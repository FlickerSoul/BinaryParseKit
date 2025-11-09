//
//  StructParseAction.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//
import SwiftSyntax

enum StructParseAction {
    case parse(ParseMacroInfo)
    case skip(SkipMacroInfo)

    var source: Syntax {
        switch self {
        case let .parse(parse):
            parse.source
        case let .skip(skip):
            skip.source
        }
    }
}
