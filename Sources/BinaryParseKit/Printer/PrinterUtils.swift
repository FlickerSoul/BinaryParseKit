//
//  PrinterUtils.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

/// - Note: This function is intended to be used only by the macro system.
public func __getPrinterIntel<T>(_ value: T) throws -> PrinterIntel {
    if let intel = (value as? Printable) {
        return try intel.printerIntel()
    } else {
        throw PrinterError.notPrintable(type: T.self)
    }
}
