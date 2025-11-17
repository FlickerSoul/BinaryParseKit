//
//  ParsablePrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//

public enum ParsablePrinterError: Swift.Error {
    case noPrinterIntel
    case intelConstructionFailed(underlying: any Error)
}

public protocol ParsablePrinter {
    associatedtype PrinterOutput

    func print(_ intel: PrinterIntel) throws(ParsablePrinterError) -> PrinterOutput
}

public extension ParsablePrinter {
    func print(_ intel: StructPrintIntel) throws(ParsablePrinterError) -> PrinterOutput {
        try print(.struct(intel))
    }

    func print(_ intel: EnumCasePrinterIntel) throws(ParsablePrinterError) -> PrinterOutput {
        try print(.enum(intel))
    }

    func print(_ intel: BuiltInPrinterIntel) throws(ParsablePrinterError) -> PrinterOutput {
        try print(.builtIn(intel))
    }

    func print(_ printable: any Printable) throws(ParsablePrinterError) -> PrinterOutput {
        try printable.printParsed(printer: self)
    }
}
