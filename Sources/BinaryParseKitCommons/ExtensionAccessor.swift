//
//  ExtensionAccessor.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

/// This enum represents the access level of an extension in Swift, with a few extra cases
public enum ExtensionAccessor: ExpressibleByUnicodeScalarLiteral, Sendable, Codable {
    public typealias UnicodeScalarLiteralType = String

    /// Same as public keyword
    case `public`
    /// Same as package keyword
    case package
    /// Same as internal keyword
    case `internal`
    /// Same as fileprivate keyword
    case `fileprivate`
    /// Same as private keyword
    case `private`
    /// This specifier indicates that the extension should follow the access level of the type it extends
    case follow
    /// Represents an unknown or unsupported access level, which will be raised as macro error.
    case unknown(String)

    /// All allowed cases for ExtensionAccessor
    ///
    /// This includes all the defined access levels except for the ``ExtensionAccessor/unknown(_:)`` case.
    public static var allowedCases: [ExtensionAccessor] {
        [.public, .package, .internal, .fileprivate, .private, .follow]
    }

    /// A textual representation of the access level.
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

    /// Initializes an `ExtensionAccessor` from a unicode scalar literal.
    ///
    /// - Note: It tries to match the provided string with valid levels specified in ``ExtensionAccessor/allowedCases``,
    /// or default to ``ExtensionAccessor/unknown(_:)``.
    public init(unicodeScalarLiteral value: String) {
        self = ExtensionAccessor
            .allowedCases
            .first { access in
                access.description == value
            } ?? .unknown(value)
    }
}
