//
//  Misc.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/18/25.
//

import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(BinaryParseKitMacros)
    import BinaryParseKitMacros

    nonisolated(unsafe) let testMacros: [String: Macro.Type] = [
        "ParseStruct": ConstructStructParseMacro.self,
        "parse": ByteParsingMacro.self,
        "skip": SkipParsingMacro.self,
        "parseRest": ByteParsingMacro.self,
    ]
    let testMacroSpec = testMacros.mapValues { MacroSpec(type: $0) }
    let shouldRunMacroTest = true
#else
    let testMacroSpec = [String: MacroSpec]()
    let shouldRunMacroTest = false
#endif

let macroFailureHandler = { @Sendable (failureSpec: TestFailureSpec) in
    _ = Issue.record(
        Comment(stringLiteral: failureSpec.message),
        sourceLocation: failureSpec.location.sourceLocation
    )
}
