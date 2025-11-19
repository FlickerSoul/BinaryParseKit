//
//  Printable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/13/25.
//

/// A protocol for types that can be printed in a format specified by `printer` that conforms to ``Printer``.
///
/// The conforming type must implement the `printerIntel()` method to provide the necessary information for printing.
public protocol Printable {
    func printParsed<P: Printer>(printer: P) throws(PrinterError) -> P.PrinterOutput

    func printerIntel() throws -> PrinterIntel
}

public extension Printable {
    func printParsed<P: Printer>(printer: P) throws(PrinterError) -> P.PrinterOutput {
        let intel: PrinterIntel
        do {
            intel = try printerIntel()
        } catch let error as PrinterError {
            throw error
        } catch {
            throw .intelConstructionFailed(underlying: error)
        }

        do {
            return try printer.print(intel)
        } catch let error as PrinterError {
            throw error
        } catch {
            throw .printingError(underlying: error)
        }
    }
}
