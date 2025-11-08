//
//  Misc.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/18/25.
//

import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(BinaryParseKitMacros)
    import BinaryParseKitMacros

    private nonisolated(unsafe) let testMacros: [String: Macro.Type] = [
        "ParseStruct": ConstructStructParseMacro.self,
        "parse": ByteParsingMacro.self,
        "skip": SkipParsingMacro.self,
        "parseRest": ByteParsingMacro.self,
        "ParseEnum": ConstructEnumParseMacro.self,
        "match": ByteParsingMacro.self,
        "matchDefault": ByteParsingMacro.self,
        "matchAndTake": ByteParsingMacro.self,
    ]
    private let testMacroSpec = testMacros.mapValues { MacroSpec(type: $0) }
    private let shouldRunMacroTest = true
#else
    private let testMacroSpec = [String: MacroSpec]()
    private let shouldRunMacroTest = false
#endif

let macroFailureHandler = { @Sendable (failureSpec: TestFailureSpec) in
    _ = Issue.record(
        Comment(stringLiteral: failureSpec.message),
        sourceLocation: failureSpec.location.sourceLocation,
    )
}

func assertMacroExpansion(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macroSpecs: [String: MacroSpec] = testMacroSpec,
    applyFixIts: [String]? = nil,
    fixedSource expectedFixedSource: String? = nil,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
) {
    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        applyFixIts: applyFixIts,
        fixedSource: expectedFixedSource,
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: macroFailureHandler,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column,
    )
}

@Suite(.disabled(if: !shouldRunMacroTest, "macros are not supported and cannot be imported for testing"))
struct BinaryParseKitMacroTests {}
