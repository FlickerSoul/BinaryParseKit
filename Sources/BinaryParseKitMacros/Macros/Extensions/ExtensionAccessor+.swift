//
//  ExtensionAccessor+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/26/25.
//

import BinaryParseKitCommons
import SwiftSyntax

extension ExtensionAccessor {
    func getAccessorToken(defaultAccessor: TokenKind) -> TokenKind? {
        switch self {
        case .public: .keyword(.public)
        case .package: .keyword(.package)
        case .internal: .keyword(.internal)
        case .fileprivate: .keyword(.fileprivate)
        case .private: .keyword(.private)
        case .follow: defaultAccessor
        case .unknown: nil
        }
    }
}
