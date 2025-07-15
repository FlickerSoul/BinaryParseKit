//
//  ParseStructMacroError.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/15/25.
//
import SwiftDiagnostics

enum ParseStructMacroError: Error, DiagnosticMessage {
    case invalidParseStruct
    case onlyStructsAreSupported
    case noParseAttributeOnVariableDecl
    case variableDeclNoTypeAnnotation
    case notIdentifierDef
    case invalidTypeAnnotation
    case multipleOrNonTrailingParseRest
    case emptyParse
    case unknownParseArgument(String)
    case parseAccessorVariableDecl
    case fatalError(message: String)
    case failedExpectation(message: String)

    var message: String {
        switch self {
        case .invalidParseStruct:
            "@ParseStruct is not used correctly."
        case .onlyStructsAreSupported:
            "@ParseStruct only supports structs. Please use a struct declaration or other macros."
        case .noParseAttributeOnVariableDecl:
            "The variable declaration must have a `@parse` attribute."
        case .variableDeclNoTypeAnnotation:
            "Variable declarations must have a type annotation to be parsed."
        case .notIdentifierDef:
            "Variable declaration must be an identifier definition."
        case .invalidTypeAnnotation:
            "Invalid type annotation in variable declaration. Expected a valid type."
        case .multipleOrNonTrailingParseRest:
            "Multiple or non-trailing `@parseRest` attributes are not allowed. Only one trailing `@parseRest` is permitted."
        case .emptyParse:
            "No variables with `@parse` attribute found in the struct. Ensure at least one variable is marked for parsing."
        case let .unknownParseArgument(argument):
            "Unknown argument in `@parse`: '\(argument)'. Please check the attribute syntax."
        case .parseAccessorVariableDecl:
            "The variable declaration with accessor(s) (`get` and `set`) cannot be parsed."
        case let .fatalError(message):
            "Fatal error: \(message)"
        case let .failedExpectation(message: message):
            "Failed expectation: \(message)"
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(domain: "observer.universe.BinaryParseKit", id: "\(self)")
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .invalidParseStruct, .onlyStructsAreSupported, .noParseAttributeOnVariableDecl,
             .variableDeclNoTypeAnnotation, .notIdentifierDef, .invalidTypeAnnotation,
             .multipleOrNonTrailingParseRest, .unknownParseArgument, .parseAccessorVariableDecl, .fatalError,
             .failedExpectation:
            .error
        case .emptyParse:
            .warning
        }
    }
}
