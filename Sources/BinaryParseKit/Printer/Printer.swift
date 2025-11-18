//
//  Printer.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//

public enum PrinterError: Swift.Error {
    case noPrinterIntel
    case intelConstructionFailed(underlying: any Error)
    case notPrintable(type: Any.Type)
}

public protocol Printer {
    associatedtype PrinterOutput

    func print(_ intel: PrinterIntel) throws(PrinterError) -> PrinterOutput
}

public extension Printer {
    func print(_ intel: PrinterIntel.StructPrintIntel) throws(PrinterError) -> PrinterOutput {
        try print(.struct(intel))
    }

    func print(_ intel: PrinterIntel.EnumCasePrinterIntel) throws(PrinterError) -> PrinterOutput {
        try print(.enum(intel))
    }

    func print(_ intel: PrinterIntel.BuiltInPrinterIntel) throws(PrinterError) -> PrinterOutput {
        try print(.builtIn(intel))
    }

    func print(_ printable: any Printable) throws(PrinterError) -> PrinterOutput {
        try printable.printParsed(printer: self)
    }
}
