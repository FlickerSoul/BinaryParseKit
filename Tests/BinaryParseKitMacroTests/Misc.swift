//
//  Misc.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/18/25.
//

import SwiftSyntaxMacros
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(BinaryParseKitMacros)
    import BinaryParseKitMacros

    let testMacros: [String: Macro.Type] = [
        "ParseStruct": ConstructStructParseMacro.self,
        "parse": EmptyPeerMacro.self,
        "skip": EmptyPeerMacro.self,
        "parseRest": EmptyPeerMacro.self,
        "ParseEnum": ConstructEnumParseMacro.self,
        "match": EmptyPeerMacro.self,
        "matchDefault": EmptyPeerMacro.self,
        "matchAndTake": EmptyPeerMacro.self,
    ]
    private let shouldRunMacroTest = true
#else
    let testMacros: [String: Macro.Type] = [:]
    private let shouldRunMacroTest = false
#endif

@Suite(.disabled(if: !shouldRunMacroTest, "macros are not supported and cannot be imported for testing"))
struct BinaryParseKitMacroTests {}
