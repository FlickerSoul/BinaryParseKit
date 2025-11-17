//
//  ByteArrayPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//
import BinaryParsing

public struct ByteArrayPrinter: ParsablePrinter {
    public func print(_ intel: PrinterIntel) throws(ParsablePrinterError) -> [UInt8] {
        printInternal(intel, byteCount: nil, endianness: nil)
    }

    func printInternal(_ intel: PrinterIntel, byteCount: Int?, endianness: Endianness?) -> [UInt8] {
        var results: [UInt8] = []

        switch intel {
        case let .struct(structPrintIntel):
            for field in structPrintIntel.fields {
                let fieldBytes = printInternal(field.intel, byteCount: field.byteCount, endianness: field.endianness)
                results.append(contentsOf: fieldBytes)
            }
        case let .enum(enumCasePrinterIntel):
            if case .matchAndTake = enumCasePrinterIntel.parseType {
                results.append(contentsOf: enumCasePrinterIntel.bytes)
            }
            for field in enumCasePrinterIntel.fields {
                results.append(contentsOf: printInternal(
                    field.intel,
                    byteCount: field.byteCount,
                    endianness: field.endianness,
                ))
            }
        case let .builtIn(builtInPrinterIntel):
            results.append(
                contentsOf: endianness?.isLittleEndian == true
                    ? builtInPrinterIntel.bytes.reversed()
                    : builtInPrinterIntel.bytes,
            )
        case let .skip(skipPrinterIntel):
            results = Array(repeating: 0, count: skipPrinterIntel.byteCount)
        }

        if let byteCount {
            return Array(results.prefix(byteCount))
        } else {
            return results
        }
    }
}

public extension ParsablePrinter where Self == ByteArrayPrinter {
    static var byteArray: Self {
        ByteArrayPrinter()
    }
}
