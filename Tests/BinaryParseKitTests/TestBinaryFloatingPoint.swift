//
//  TestBinaryFloatingPoint.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/16/25.
//

@testable import BinaryParseKit
@testable import BinaryParseKitCommons
import BinaryParsing
import Testing

extension Endianness: @unchecked @retroactive Sendable {}

@Suite("BinaryFloatingPoint")
struct TestBinaryFloatingPoint {
    @Test
    func parsingFromByteArray() throws {
        try testingImpl(
            [0xDE, 0xAD, 0xBE, 0xEF],
            to: Float16.self,
            endianness: .big,
            expected: .init(bitPattern: 0xDEAD)
        )
        try testingImpl(
            [0xDE, 0xAD, 0xBE, 0xEF],
            to: Float16.self,
            endianness: .little,
            expected: .init(bitPattern: 0xADDE)
        )
        try testingImpl(
            [0xDE, 0xAD, 0xBE, 0xEF],
            to: Float.self,
            endianness: .big,
            expected: .init(bitPattern: 0xDEAD_BEEF)
        )
        try testingImpl(
            [0xDE, 0xAD, 0xBE, 0xEF],
            to: Float.self,
            endianness: .little,
            expected: .init(bitPattern: 0xEFBE_ADDE)
        )
        try testingImpl(
            [0xAB, 0xAD, 0xCA, 0xFE, 0xAA, 0xC0, 0xFF, 0xEE],
            to: Double.self,
            endianness: .big,
            expected: .init(bitPattern: 0xABAD_CAFE_AAC0_FFEE)
        )
        try testingImpl(
            [0xAB, 0xAD, 0xCA, 0xFE, 0xAA, 0xC0, 0xFF, 0xEE],
            to: Double.self,
            endianness: .little,
            expected: .init(bitPattern: 0xEEFF_C0AA_FECA_ADAB)
        )
    }

    func testingImpl<T: EndianParsable & BinaryFloatingPoint>(
        _ data: [UInt8],
        to _: T.Type,
        endianness: Endianness,
        expected: T
    ) throws {
        let actual = try T(parsing: data, endianness: endianness)
        #expect(actual == expected)
    }
}
