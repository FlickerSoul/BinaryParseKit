//
//  VariableDeclSyntax+.swift
//  ParseKit
//
//  Created by Larry Zeng on 3/8/25.
//

import SwiftSyntax

extension VariableDeclSyntax {
    var isStaticDecl: Bool {
        modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static)
        }
    }
}

extension PatternBindingListSyntax.Element {
    var hasAccessor: Bool {
        accessorBlock != nil
    }

    var hasInitializer: Bool {
        initializer != nil
    }

    var hasTypeAnnotation: Bool {
        typeAnnotation != nil
    }

    var identifierName: TokenSyntax? {
        pattern.as(IdentifierPatternSyntax.self)?.identifier
    }

    var typeName: TypeSyntax? {
        typeAnnotation?.type
    }
}
