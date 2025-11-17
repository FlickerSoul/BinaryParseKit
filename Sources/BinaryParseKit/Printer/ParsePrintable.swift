//
//  Printable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/13/25.
//
public protocol Printable {
    func printParsed<P: ParsablePrinter>(printer: P) throws(ParsablePrinterError) -> P.PrinterOutput

    func printerIntel() throws -> PrinterIntel
}

public extension Printable {
    func printParsed<P: ParsablePrinter>(printer: P) throws(ParsablePrinterError) -> P.PrinterOutput {
        do {
            let intel = try printerIntel()
            return try printer.print(intel)
        } catch let error as ParsablePrinterError {
            throw error
        } catch {
            throw .intelConstructionFailed(underlying: error)
        }
    }
}
