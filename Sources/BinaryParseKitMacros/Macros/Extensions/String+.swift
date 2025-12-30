//
//  String+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 12/30/25.
//

extension String {
    func escapeForVariableName() -> String {
        replacingOccurrences(of: ".", with: "_")
    }
}
