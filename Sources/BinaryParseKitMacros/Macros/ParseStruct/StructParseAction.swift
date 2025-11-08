//
//  StructParseAction.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//
import SwiftSyntax

enum StructParseAction {
    case parse(StructFieldParseInfo)
    case skip(ParseSkipInfo)

    var source: Syntax {
        switch self {
        case let .parse(parse):
            parse.source
        case let .skip(skip):
            skip.source
        }
    }
}
