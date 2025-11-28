//
//  ConstructParseBitmaskMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum ParseBitmaskMacroError: Error, DiagnosticMessage {
    case onlyStructsAreSupported

    var message: String {
        switch self {
        case .onlyStructsAreSupported: "@ParseBitmask can only be applied to structs."
        }
    }

    var diagnosticID: SwiftDiagnostics.MessageID {
        .init(
            domain: "observer.universe.BinaryParseKit.ParseBitmaskMacroError",
            id: "\(self)",
        )
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .onlyStructsAreSupported: .error
        }
    }
}

public struct ConstructParseBitmaskMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            throw ParseBitmaskMacroError.onlyStructsAreSupported
        }

        let type = type.trimmed

        let accessorInfo = try extractAccessor(
            from: node,
            attachedTo: declaration,
            in: context,
        )

        // extract mask macro info

        let bitmaskParsableExtension =
            try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.bitmaskParsableProtocol)") {
                try VariableDeclSyntax("static var bitCount: Int") {
                    #"fatalError("TODO")"#
                }

                // FIXME: accessors
                try InitializerDeclSyntax(
                    "\(accessorInfo.parsingAccessor) init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
                ) {
                    #"fatalError("TODO")"#
                }
            }

        return [bitmaskParsableExtension]
    }
}
