//
//  MaskMacroCollector.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

import SwiftSyntax
import SwiftSyntaxMacros

class MaskMacroCollector: SyntaxVisitor {
    private let context: any MacroExpansionContext
    private(set) var maskInfoCollection: [MaskMacroInfo] = []

    init(context: some MacroExpansionContext) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }
}
