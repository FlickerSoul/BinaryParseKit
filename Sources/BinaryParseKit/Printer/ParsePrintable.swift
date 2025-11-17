//
//  Printable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/13/25.
//
public protocol Printable {
    func printParsed<P: ParsablePrinter>(printer: P) throws(ParsablePrinterError) -> P.PrinterOutput

    func parsedIntel() -> PrinterIntel
}

public extension Printable {
    func printParsed<P: ParsablePrinter>(printer: P) throws(ParsablePrinterError) -> P.PrinterOutput {
        let intel = parsedIntel()
        return try printer.print(intel)
    }
}
