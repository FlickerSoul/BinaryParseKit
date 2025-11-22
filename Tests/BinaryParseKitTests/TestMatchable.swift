//
//  TestMatchable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/22/25.
//

import BinaryParseKit
import Testing

extension String: Matchable {
    public func bytesToMatch() -> [UInt8] {
        utf8.map(\.self)
    }
}

@Suite
struct MatchableTests {
    enum RawRepresentableMatch: UInt8, Matchable, Codable {
        case success = 0x00
        case failure = 0x01
    }

    @Test(arguments: [
        RawRepresentableMatch.success,
        .failure,
    ])
    func `byte generated from RawRepresentable`(_ input: RawRepresentableMatch) {
        #expect(input.bytesToMatch() == [input.rawValue])
    }

    enum CustomRawRepresentable: String, Matchable, Codable {
        case first = "one"
        case second = "two"
        case third = "three"
    }

    @Test(arguments: [
        CustomRawRepresentable.first,
        .second,
        .third,
    ])
    func `bytes generated from CustomRawRepresentable`(_ input: CustomRawRepresentable) {
        #expect(input.bytesToMatch() == Array(input.rawValue.utf8))
    }
}
