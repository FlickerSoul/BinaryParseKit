//
//  Printer.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//

public enum PrinterError: Swift.Error {
    /// Indicates that the construction of printer intel failed, with the underlying error provided.
    case intelConstructionFailed(underlying: any Error)
    /// Indicates that the provided type does not conform to ``Printable``.
    case notPrintable(type: Any.Type)
    /// Indicates that error is thrown by underling printer during printing process.
    case printingError(underlying: any Error)
}

public protocol Printer {
    /// The output type produced by the printer. For example, this could be `String`, `Data`, or any other type that
    /// represents the printed output.
    associatedtype PrinterOutput

    /// Prints the provided ``PrinterIntel``
    /// - Returns: An instance of ``PrinterOutput`` representing the printed result.
    func print(_ intel: PrinterIntel) throws -> PrinterOutput
}

public extension Printer {
    func print(_ intel: PrinterIntel.StructPrintIntel) throws -> PrinterOutput {
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
