//
//  ByteArrayPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//
import BinaryParsing

public struct ByteArrayPrinter: ParsablePrinter {
    public init() {}

    public func print(_ intel: PrinterIntel) throws(ParsablePrinterError) -> [UInt8] {
        printInternal(intel, byteCount: nil, endianness: nil)
    }

    func printInternal(_ intel: PrinterIntel, byteCount: Int?, endianness: Endianness?) -> [UInt8] {
        switch intel {
        case let .struct(structPrintIntel):
            var results: [UInt8] = []
            for field in structPrintIntel.fields {
                let fieldBytes = printInternal(field.intel, byteCount: field.byteCount, endianness: field.endianness)
                results.append(contentsOf: fieldBytes)
            }
            return Self.trimBytes(results, to: byteCount)
        case let .enum(enumCasePrinterIntel):
            var results: [UInt8] = []
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
            return Self.trimBytes(results, to: byteCount)
        case let .builtIn(builtInPrinterIntel):
            let bytes = Self.trimBytes(builtInPrinterIntel.bytes, to: byteCount)
            if endianness?.isLittleEndian == true, !builtInPrinterIntel.fixedEndianness {
                return bytes.reversed()
            } else {
                return bytes
            }
        case let .skip(skipPrinterIntel):
            return Array(repeating: 0, count: skipPrinterIntel.byteCount)
        }
    }

    private static func trimBytes(_ bytes: [UInt8], to byteCount: Int?) -> [UInt8] {
        if let byteCount {
            Array(bytes.prefix(byteCount))
        } else {
            bytes
        }
    }
}

public extension ParsablePrinter where Self == ByteArrayPrinter {
    static var byteArray: Self {
        ByteArrayPrinter()
    }
}
