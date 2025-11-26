//
//  ExtensionAccess.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

public enum ExtensionAccess: String, CaseIterable, ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = String

    case `public`
    case package
    case `internal`
    case `fileprivate`
    case `private`
    case follow
    case unknown

    public init(unicodeScalarLiteral value: String) {
        for access in ExtensionAccess.allCases where access.rawValue == value {
            self = access
        }

        self = .unknown
    }
}
