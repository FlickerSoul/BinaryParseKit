//
//  ConsructParseEnumMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/26/25.
//

import BinaryParsing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConstructEnumParseMacro: ExtensionMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in _: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else {
            throw ParseEnumMacroError.onlyEnumsAreSupported
        }

        let parsingExtension = try ExtensionDeclSyntax("extension \(type): BinaryParseKit.Parsable") {
            try InitializerDeclSyntax("init(parsing input: inout ParserSpan) throws(BinaryParsing.ThrownParsingError)") {}
        }

        return [parsingExtension]
    }
}
