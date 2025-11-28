//
//  BitmaskParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

public protocol BitmaskParsable: Parsable {
    static var bitCount: Int { get }
}
