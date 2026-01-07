//
//  TestDefaultHexStringPrinterFormatter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

import BinaryParseKit
import Testing

extension PrinterTests { @Suite struct DefaultHexStringPrinterFormatterTest {} }

// MARK: - DefaultHexStringPrinterFormatter Tests

extension PrinterTests.DefaultHexStringPrinterFormatterTest {
    // MARK: - Basic Formatting Tests

    @Test
    func `format with defaults`() {
        let formatter = DefaultHexStringPrinterFormatter()
        let result = formatter.format(bytes: [0x01, 0x02, 0x03, 0x04])

        #expect(result == "01020304")
    }

    @Test
    func `format with space separator`() {
        let formatter = DefaultHexStringPrinterFormatter(separator: " ")
        let result = formatter.format(bytes: [0x01, 0x02, 0x03, 0x04])

        #expect(result == "01 02 03 04")
    }

    @Test
    func `format with 0x prefix`() {
        let formatter = DefaultHexStringPrinterFormatter(prefix: "0x")
        let result = formatter.format(bytes: [0x01, 0x02, 0x03, 0x04])

        #expect(result == "0x010x020x030x04")
    }

    @Test
    func `format with both separator and prefix`() {
        let formatter = DefaultHexStringPrinterFormatter(separator: ", ", prefix: "0x")
        let result = formatter.format(bytes: [0x01, 0x02, 0x03, 0x04])

        #expect(result == "0x01, 0x02, 0x03, 0x04")
    }

    // MARK: - Character Case Tests

    @Test
    func `format with lowercase character case`() {
        let formatter = DefaultHexStringPrinterFormatter(characterCase: .lower)
        let result = formatter.format(bytes: [0xAB, 0xCD, 0xEF])

        #expect(result == "abcdef")
    }

    @Test
    func `format lowercase with separator`() {
        let formatter = DefaultHexStringPrinterFormatter(separator: " ", characterCase: .lower)
        let result = formatter.format(bytes: [0xDE, 0xAD, 0xBE, 0xEF])

        #expect(result == "de ad be ef")
    }

    @Test
    func `format lowercase with prefix`() {
        let formatter = DefaultHexStringPrinterFormatter(prefix: "0x", characterCase: .lower)
        let result = formatter.format(bytes: [0xAA, 0xBB])

        #expect(result == "0xaa0xbb")
    }

    @Test
    func `format lowercase with separator and prefix`() {
        let formatter = DefaultHexStringPrinterFormatter(separator: ", ", prefix: "0x", characterCase: .lower)
        let result = formatter.format(bytes: [0x0A, 0x0B, 0x0C])

        #expect(result == "0x0a, 0x0b, 0x0c")
    }

    // MARK: - All Hex Digits Tests

    @Test
    func `format all hex digits uppercase`() {
        let formatter = DefaultHexStringPrinterFormatter(characterCase: .upper)
        let result = formatter.format(bytes: [0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F])

        #expect(result == "0A0B0C0D0E0F")
    }

    @Test
    func `format all hex digits lowercase`() {
        let formatter = DefaultHexStringPrinterFormatter(characterCase: .lower)
        let result = formatter.format(bytes: [0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F])

        #expect(result == "0a0b0c0d0e0f")
    }
}
