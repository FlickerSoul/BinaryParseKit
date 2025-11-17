//
//  HexStringPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

public protocol HexStringPrinterFormatter {
    typealias ByteSource = [UInt8]

    func format(bytes: ByteSource) -> String
}

public struct DefaultHexStringPrinterFormatter: HexStringPrinterFormatter {
    public enum CharacterCase {
        case upper
        case lower

        var formatString: StaticString {
            switch self {
            case .upper: "%02X"
            case .lower: "%02x"
            }
        }
    }

    let separator: String
    let prefix: String
    let characterCase: CharacterCase

    /// Create a default hex string formatter
    /// - Parameters:
    ///  - separator: The separator between each byte. Default is empty string.
    ///  - prefix: The prefix for each byte which will be prefixed before `%02X` or `%02x`. Default is empty string.
    ///  - characterCase: The character case for hex digits. Default is ``CharacterCase/upper``
    public init(
        separator: String = "",
        prefix: String = "",
        characterCase: CharacterCase = .upper,
    ) {
        self.separator = separator
        self.prefix = prefix
        self.characterCase = characterCase
    }

    public func format(bytes: ByteSource) -> String {
        bytes
            .map { unsafe String(format: "\(prefix)\(characterCase.formatString)", $0) }
            .joined(separator: separator)
    }
}

public struct HexStringPrinter<F: HexStringPrinterFormatter>: ParsablePrinter {
    public let formatter: F

    public init(separator: String = "", prefix: String = "") where F == DefaultHexStringPrinterFormatter {
        formatter = DefaultHexStringPrinterFormatter(
            separator: separator,
            prefix: prefix,
        )
    }

    public init(formatter: F) {
        self.formatter = formatter
    }

    public func print(_ intel: PrinterIntel) throws(ParsablePrinterError) -> String {
        let byteSource = try ByteArrayPrinter().print(intel)
        return formatter.format(bytes: byteSource)
    }
}

public extension ParsablePrinter where Self == HexStringPrinter<DefaultHexStringPrinterFormatter> {
    static func hexString(separator: String = "", prefix: String = "") -> Self {
        HexStringPrinter(
            separator: separator,
            prefix: prefix,
        )
    }
}

public extension ParsablePrinter {
    static func hexString<T: HexStringPrinterFormatter>(formatter: T) -> HexStringPrinter<T> {
        HexStringPrinter(formatter: formatter)
    }
}
