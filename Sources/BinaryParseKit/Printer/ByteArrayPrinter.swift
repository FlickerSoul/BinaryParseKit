//
//  ByteArrayPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//
import BinaryParsing

/// A printer that converts ``PrinterIntel`` into a byte array.
public struct ByteArrayPrinter: Printer {
    public init() {}

    public func print(_ intel: PrinterIntel) throws -> [UInt8] {
        printInternal(intel, byteCount: nil, endianness: nil)
    }

    // FIXME: too many allocations
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
            let littleEndian = endianness?.isLittleEndian == true && !builtInPrinterIntel.fixedEndianness
            return Self.trimBytes(
                littleEndian ? builtInPrinterIntel.bytes.reversed() : builtInPrinterIntel.bytes,
                to: byteCount,
                bigEndian: !littleEndian,
            )
        case let .skip(skipPrinterIntel):
            return Array(repeating: 0, count: skipPrinterIntel.byteCount)
        }
    }

    private static func trimBytes(_ bytes: [UInt8], to byteCount: Int?, bigEndian: Bool = true) -> [UInt8] {
        if let byteCount {
            if bigEndian {
                Array(bytes.suffix(byteCount))
            } else {
                Array(bytes.prefix(byteCount))
            }
        } else {
            bytes
        }
    }
}

public extension Printer where Self == ByteArrayPrinter {
    static var byteArray: Self {
        ByteArrayPrinter()
    }
}
