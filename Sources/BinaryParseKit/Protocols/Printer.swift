//
//  Printer.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//

public protocol Printer {
    /// The output type produced by the printer. For example, this could be `String`, `Data`, or any other type that
    /// represents the printed output.
    associatedtype PrinterOutput

    /// Prints the provided ``PrinterIntel``
    /// - Returns: An instance of ``PrinterOutput`` representing the printed result.
    func print(_ intel: PrinterIntel) throws -> PrinterOutput
}

public extension Printer {
    func print(_ intel: PrinterIntel.StructPrinterIntel) throws -> PrinterOutput {
        try print(.struct(intel))
    }

    func print(_ intel: PrinterIntel.EnumCasePrinterIntel) throws -> PrinterOutput {
        try print(.enum(intel))
    }

    func print(_ intel: PrinterIntel.BuiltInPrinterIntel) throws -> PrinterOutput {
        try print(.builtIn(intel))
    }

    func print(_ printable: any Printable) throws(PrinterError) -> PrinterOutput {
        try printable.printParsed(printer: self)
    }
}
