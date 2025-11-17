//
//  HexStringPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

public struct HexStringPrinter: ParsablePrinter {
    let separator: String
    let prefix: String

    public func print(_ intel: PrinterIntel) throws(ParsablePrinterError) -> String {
        try ByteArrayPrinter()
            .print(intel)
            .map { unsafe String(format: "\(prefix)%02X", $0) }
            .joined(separator: separator)
    }
}

public extension ParsablePrinter where Self == HexStringPrinter {
    static func hexString(separator: String = "", prefix: String = "") -> Self {
        HexStringPrinter(
            separator: separator,
            prefix: prefix,
        )
    }
}
