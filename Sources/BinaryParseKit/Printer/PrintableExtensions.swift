//
//  PrintableExtensions.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/15/25.
//

// MARK: - Integer

extension FixedWidthInteger {
    func toBytes() -> [UInt8] {
        unsafe withUnsafeBytes(of: bigEndian, Array.init)
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
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension UInt128: Printable {}

extension Int8: Printable {}
extension Int16: Printable {}
extension Int32: Printable {}
extension Int: Printable {}
extension Int64: Printable {}
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Int128: Printable {}

// MARK: - Floating Point

extension BinaryFloatingPoint {
    func toBytes() -> [UInt8] {
        unsafe withUnsafeBytes(of: self, Array.init)
    }
}

public extension Printable where Self: BinaryFloatingPoint {
    func printerIntel() -> PrinterIntel {
        .builtIn(
            .init(bytes: toBytes()),
        )
    }
}

extension Float16: Printable {}
extension Float: Printable {}
extension Double: Printable {}

// MARK: - Array

extension [UInt8]: Printable {
    public func printerIntel() -> PrinterIntel {
        .builtIn(
            .init(
                bytes: self,
                fixedEndianness: true,
            ),
        )
    }
}
