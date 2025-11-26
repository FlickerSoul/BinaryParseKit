//
//  ExtensionAccessor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

public enum ExtensionAccessor: ExpressibleByUnicodeScalarLiteral, Sendable, Codable {
    public typealias UnicodeScalarLiteralType = String

    case `public`
    case package
    case `internal`
    case `fileprivate`
    case `private`
    case follow
    case unknown(String)

    public static var allowedCases: [ExtensionAccessor] {
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
        self = ExtensionAccessor
            .allowedCases
            .first { access in
                access.description == value
            } ?? .unknown(value)
    }
}
