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

    func hasParseAttribute() -> Bool {
        let parseAttributes = attributes
            .filter { attribute in
                guard case let .attribute(attribute) = attribute else {
                    return false
                }

                let attributeIdentifier = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.tokenKind
                return attributeIdentifier == .identifier("parse") || attributeIdentifier == .identifier("parseRest")
            }

        if parseAttributes.count != 1 {
            return false
        }

        return true
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

    var identifierName: String? {
        if case let .identifier(name) = pattern.as(IdentifierPatternSyntax.self)?.identifier.tokenKind {
            name
        } else {
            nil
        }
    }

    var typeName: String? {
        typeAnnotation?.type.description
    }
}
