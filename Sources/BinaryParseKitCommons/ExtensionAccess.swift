//
//  ExtensionAccess.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

public enum ExtensionAccess: ExpressibleByUnicodeScalarLiteral, Sendable {
    public typealias UnicodeScalarLiteralType = String

    case `public`
    case package
    case `internal`
    case `fileprivate`
    case `private`
    case follow
    case unknown(String)

    public static var allowedCases: [ExtensionAccess] {
        [.public, .package, .internal, .fileprivate, .private, .follow]
    }

    public var description: String {
        switch self {
        case .public: "public"
        case .package: "package"
        case .internal: "internal"
        case .fileprivate: "fileprivate"
        case .private: "private"
        case .follow: "follow"
        case let .unknown(value): "unknown(\(value))"
        }
    }

    public init(unicodeScalarLiteral value: String) {
        for access in ExtensionAccess.allowedCases where access.description == value {
            self = access
        }

        self = .unknown(value)
    }
}
