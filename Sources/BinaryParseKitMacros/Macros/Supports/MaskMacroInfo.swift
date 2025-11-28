//
//  MaskMacroInfo.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import SwiftSyntax

struct MaskMacroInfo {
    enum BitCount {
        case specified(Int)
        case inferred
    }

    let bitCount: BitCount
    let name: TokenSyntax
    let source: Syntax
}
