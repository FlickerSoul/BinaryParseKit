//
//  ParseEnumMacroError.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//
import SwiftDiagnostics

enum ParseEnumMacroError: Error, DiagnosticMessage {
    case onlyEnumsAreSupported
    case onlyOneEnumDeclarationForEachCase
    case parameterParseNumberNotMatch
    case matchMustProceedParse
    case missingCaseMatchMacro
    case defaultCaseMustBeLast
    case unexpectedError(description: String)

    var message: String {
        switch self {
        case .onlyEnumsAreSupported: "Only enums are supported by this macro."
        case .onlyOneEnumDeclarationForEachCase: "Only one enum declaration is allowed for each case."
        case .parameterParseNumberNotMatch:
            "The number of the parse macros does not match the number of cases in the enum."
        case .matchMustProceedParse: "The `match` macro must proceed all `parse` macro."
        case .missingCaseMatchMacro: "A `case` declaration must has a `match` macro."
        case .defaultCaseMustBeLast: "The `matchDefault` case must be the last case in the enum."
        case let .unexpectedError(description: description):
            "Unexpected error: \(description)"
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(domain: "observer.universe.BinaryParseKit.ParseEnumMacroError", id: "\(self)")
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        .error
    }
}
