//
//  Utilities.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/6/25.
//
import SwiftSyntax

func generateAssertParsable() throws -> (name: TokenSyntax, func: FunctionDeclSyntax) {
    let funcName: TokenSyntax = .identifier("__assertParsable")

    return try (
        funcName,
        FunctionDeclSyntax(
            "@inline(__always) func \(funcName)<T: \(raw: Constants.parsableProtocol)>(_ type: T.Type) {}",
        ),
    )
}

func generateAssertSizedParsable() throws -> (name: TokenSyntax, func: FunctionDeclSyntax) {
    let funcName: TokenSyntax = .identifier("__assertSizedParsable")

    return try (
        funcName,
        FunctionDeclSyntax(
            "@inline(__always) func \(funcName)<T: \(raw: Constants.sizedParsableProtocol)>(_ type: T.Type) {}",
        ),
    )
}

func generateAssertEndianParsable() throws -> (name: TokenSyntax, func: FunctionDeclSyntax) {
    let funcName: TokenSyntax = .identifier("__assertEndianParsable")

    return try (
        funcName,
        FunctionDeclSyntax(
            "@inline(__always) func \(funcName)<T: \(raw: Constants.endianParsableProtocol)>(_ type: T.Type) {}",
        ),
    )
}

func generateAssertEndianSizedParsable() throws -> (name: TokenSyntax, func: FunctionDeclSyntax) {
    let funcName: TokenSyntax = .identifier("__assertEndianSizedParsable")

    return try (
        funcName,
        FunctionDeclSyntax(
            "@inline(__always) func \(funcName)<T: \(raw: Constants.endianSizedParsableProtocol)>(_ type: T.Type) {}",
        ),
    )
}
