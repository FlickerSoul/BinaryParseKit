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
    let separator: String
    let prefix: String

    public func format(bytes: ByteSource) -> String {
        bytes
            .map { unsafe String(format: "\(prefix)%02X", $0) }
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
