//
//  PrintableExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/15/25.
//

// MARK: - Integer

extension FixedWidthInteger {
    func toBytes(useBigEndian: Bool = true) -> [UInt8] {
        unsafe withUnsafeBytes(
            of: useBigEndian ? bigEndian : littleEndian,
            Array.init,
        )
    }
}

public extension Printable where Self: FixedWidthInteger {
    func printerIntel() -> PrinterIntel {
        .builtIn(
            .init(bytes: toBytes()),
        )
    }
}

extension UInt8: Printable {}
extension UInt16: Printable {}
extension UInt32: Printable {}
extension UInt: Printable {}
extension UInt64: Printable {}
extension UInt128: Printable {}

extension Int8: Printable {}
extension Int16: Printable {}
extension Int32: Printable {}
extension Int: Printable {}
extension Int64: Printable {}
extension Int128: Printable {}

// MARK: - Floating Point

extension ExpressibleByBitPattern {
    func toBytes(useBigEndian: Bool = true) -> [UInt8] {
        unsafe withUnsafeBytes(
            of: useBigEndian ? bitPattern.bigEndian : bitPattern.littleEndian,
            Array.init,
        )
    }
}

public extension Printable where Self: ExpressibleByBitPattern {
    func printerIntel() -> PrinterIntel {
        .builtIn(
            .init(bytes: toBytes()),
        )
    }
}

extension Float16: Printable {}
extension Float: Printable {}
extension Double: Printable {}
