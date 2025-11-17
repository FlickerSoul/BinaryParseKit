//
//  Printable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/13/25.
//
public protocol Printable {
    func printParsed<P: ParsablePrinter>(printer: P) throws(ParsablePrinterError) -> P.PrinterOutput

    func parsedIntel() throws -> PrinterIntel
}

public extension Printable {
    func printParsed<P: ParsablePrinter>(printer: P) throws(ParsablePrinterError) -> P.PrinterOutput {
        let intel: PrinterIntel

        do {
            intel = try parsedIntel()
        } catch {
            throw .intelConstructionFailed(underlying: error)
        }

        return try printer.print(intel)
    }
}
