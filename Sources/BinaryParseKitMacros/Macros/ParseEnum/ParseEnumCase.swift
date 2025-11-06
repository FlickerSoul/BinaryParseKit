//
//  ParseEnumField.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//
import SwiftSyntax
import SwiftSyntaxMacros

class ParseEnumCase<C: MacroExpansionContext>: SyntaxVisitor {
    private let context: C

    init(context: C) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }
}
