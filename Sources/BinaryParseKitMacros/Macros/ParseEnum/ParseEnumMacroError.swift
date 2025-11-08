//
//  ParseEnumMacroError.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//
import SwiftDiagnostics

enum ParseEnumMacroError: Error, DiagnosticMessage {
    case onlyEnumsAreSupported
    case caseArgumentsMoreThanMacros
    case macrosMoreThanCaseArguments
    case matchMustProceedParseAndSkip
    case missingCaseMatchMacro
    case defaultCaseMustBeLast
    case onlyOneMatchDefaultAllowed
    case matchDefaultShouldBeLast
    case unexpectedError(description: String)

    var message: String {
        switch self {
        case .onlyEnumsAreSupported: "Only enums are supported by this macro."
        case .caseArgumentsMoreThanMacros:
            "The associated values in the enum case exceed the number of parse/skip macros."
        case .macrosMoreThanCaseArguments:
            "There are more parse/skip macros than the number of cases in the enum."
        case .matchMustProceedParseAndSkip: "The `match` macro must proceed all `parse` and `skip` macro."
        case .missingCaseMatchMacro: "A `case` declaration must has a `match` macro."
        case .defaultCaseMustBeLast: "The `matchDefault` case must be the last case in the enum."
        case .onlyOneMatchDefaultAllowed: "Only one `matchDefault` case is allowed in a enum."
        case .matchDefaultShouldBeLast: "The `matchDefault` case should be the last case in the enum."
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
