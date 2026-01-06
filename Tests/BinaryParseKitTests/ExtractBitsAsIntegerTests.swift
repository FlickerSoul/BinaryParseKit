//
//  ExtractBitsAsIntegerTests.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//
@testable import BinaryParseKit
import BinaryParsing
import Foundation
import Testing

@Suite("__extractBitsAsInteger Tests")
struct ExtractBitsAsIntegerTests {
    @Test("Extract 8 bits as UInt8")
    func extract8BitsAsUInt8() throws {
        let data = Data([0b1101_0011])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 8)
            #expect(value == 0b1101_0011)
        }
    }

    @Test("Extract first 4 bits (MSB-first)")
    func extractFirst4Bits() throws {
        // 0b1101_0011 - first 4 bits = 0b1101 = 13
        let data = Data([0b1101_0011])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 4)
            #expect(value == 0b1101)
        }
    }

    @Test("Extract last 4 bits (MSB-first)")
    func extractLast4Bits() throws {
        // 0b1101_0011 - last 4 bits = 0b0011 = 3
        let data = Data([0b1101_0011])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 4, count: 4)
            #expect(value == 0b0011)
        }
    }

    @Test("Extract middle 4 bits")
    func extractMiddle4Bits() throws {
        // 0b1101_0011 - bits [2,6) = 0b0100 = 4
        let data = Data([0b1101_0011])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 2, count: 4)
            #expect(value == 0b0100)
        }
    }

    @Test("Extract single bit (true)")
    func extractSingleBitTrue() throws {
        // 0b1000_0000 - bit 0 = 1
        let data = Data([0b1000_0000])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 1)
            #expect(value == 1)
        }
    }

    @Test("Extract single bit (false)")
    func extractSingleBitFalse() throws {
        // 0b0111_1111 - bit 0 = 0
        let data = Data([0b0111_1111])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 1)
            #expect(value == 0)
        }
    }

    @Test("Extract 16 bits as UInt16")
    func extract16BitsAsUInt16() throws {
        // 0x1234 in big endian
        let data = Data([0x12, 0x34])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt16.self, from: span, offset: 0, count: 16)
            #expect(value == 0x1234)
        }
    }

    @Test("Extract bits spanning byte boundary")
    func extractBitsSpanningByteBoundary() throws {
        // 0b1010_1100 0b1100_1010 - bits [4,12) spans bytes
        // bits 4-7 from byte 0: 1100
        // bits 8-11 from byte 1: 1100
        // result: 0b1100_1100 = 204
        let data = Data([0b1010_1100, 0b1100_1010])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 4, count: 8)
            #expect(value == 0b1100_1100)
        }
    }

    @Test("Extract 10 bits spanning byte boundary")
    func extract10BitsSpanningBoundary() throws {
        // 0b1010_1010 0b1100_1100 - bits [3,13)
        // bits 3-7: 01010
        // bits 8-12: 11001
        // result: 0b01010_11001 = 345
        let data = Data([0b1010_1010, 0b1100_1100])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt16.self, from: span, offset: 3, count: 10)
            #expect(value == 0b01_0101_1001)
        }
    }

    @Test("Extract zero bits returns zero")
    func extractZeroBits() throws {
        let data = Data([0xFF])
        data.withParserSpan { span in
            let value = __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 0)
            #expect(value == 0)
        }
    }

    @Test("MSB-first bit extraction per spec")
    func msbFirstBitExtractionPerSpec() throws {
        // Spec scenario: byte 0b11010011
        // Field A: 2 bits = 0b11 = 3
        // Field B: 4 bits = 0b0100 = 4
        // Field C: 2 bits = 0b11 = 3
        let data = Data([0b1101_0011])
        data.withParserSpan { span in
            let fieldA = __extractBitsAsInteger(UInt8.self, from: span, offset: 0, count: 2)
            let fieldB = __extractBitsAsInteger(UInt8.self, from: span, offset: 2, count: 4)
            let fieldC = __extractBitsAsInteger(UInt8.self, from: span, offset: 6, count: 2)

            #expect(fieldA == 3)
            #expect(fieldB == 4)
            #expect(fieldC == 3)
        }
    }
}
