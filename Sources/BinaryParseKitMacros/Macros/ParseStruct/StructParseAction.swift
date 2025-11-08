//
//  StructParseAction.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

enum StructParseAction {
    case parse(StructFieldParseInfo)
    case skip(ParseSkipInfo)

    var isParse: Bool {
        if case .parse = self {
            true
        } else {
            false
        }
    }
}
