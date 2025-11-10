//
//  ParseStoreMacroInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/10/25.
//
import BinaryParseKitCommons
import SwiftSyntax

struct ParseStoreMacroInfo {
    enum Count {
        /// A fixed byte count, specified by `byteCount` argument
        case fixed(ByteCount)
        /// An unspecified byte count, meaning it uses `Parsable` or `EndianParsable` which doesn't care about the size
        case unspecified
        /// A variable byte count, specified by `byteCountOf` argument
        case ofVariable(ExprSyntax)

        func toParseInfoCount() -> ParseMacroInfo.Count {
            switch self {
            case let .fixed(byteCount): .fixed(byteCount)
            case .unspecified: .unspecified
            case let .ofVariable(expr): .ofVariable(expr)
            }
        }
    }

    let variableName: String
    let type: TypeSyntax
    let byteCount: Count
    let endianness: ExprSyntax?
    let source: Syntax
}
