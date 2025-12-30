//
//  ParseBitmaskMacroError.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//
import SwiftDiagnostics

enum ParseBitmaskMacroError: Error, DiagnosticMessage {
    case onlyStructsAreSupported
    case fieldMustHaveMaskAttribute
    case noFieldsFound
    case fatalError(message: String)

    var message: String {
        switch self {
        case .onlyStructsAreSupported: "@ParseBitmask can only be applied to structs."
        case .fieldMustHaveMaskAttribute: "All fields in @ParseBitmask struct must have @mask attribute."
        case .noFieldsFound: "@ParseBitmask struct must have at least one field with @mask attribute."
        case let .fatalError(message): "Fatal error in ParseBitmask macro: \(message)"
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "observer.universe.BinaryParseKit.ParseBitmaskMacroError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        .error
    }
}
