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
    /// Character case for hex digits.
    public enum CharacterCase {
        /// Formats hex digits in uppercase (e.g., "0A", "FF").
        case upper
        /// Formats hex digits in lowercase (e.g., "0a", "ff").
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
    ///   - separator: The separator between each byte. Default is empty string.
    ///   - prefix: The prefix for each byte which will be placed before `%02X` or `%02x`. Default is empty string.
    ///   - characterCase: The character case for hex digits. Default is ``CharacterCase/upper``
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

/// A printer that converts byte arrays into hexadecimal string representations using a ``HexStringPrinterFormatter``.
public struct HexStringPrinter<F: HexStringPrinterFormatter>: Printer {
    public let formatter: F

    public init(formatter: F) {
        self.formatter = formatter
    }

    public func print(_ intel: PrinterIntel) throws -> String {
        let byteSource = try ByteArrayPrinter().print(intel)
        return formatter.format(bytes: byteSource)
    }
}

public extension Printer where Self == HexStringPrinter<DefaultHexStringPrinterFormatter> {
    static func hexString(
        separator: String = "",
        prefix: String = "",
        characterCase: DefaultHexStringPrinterFormatter.CharacterCase = .upper,
    ) -> Self {
        HexStringPrinter(
            formatter: DefaultHexStringPrinterFormatter(
                separator: separator,
                prefix: prefix,
                characterCase: characterCase,
            ),
        )
    }
}

public extension Printer {
    static func hexString<T: HexStringPrinterFormatter>(formatter: T) -> HexStringPrinter<T> {
        HexStringPrinter(formatter: formatter)
    }
}
