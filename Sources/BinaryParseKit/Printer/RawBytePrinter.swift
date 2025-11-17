//
//  RawBytePrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/14/25.
//

public struct HexStringPrinter: ParsablePrinter {
    public func print(_: PrinterIntel) throws(ParsablePrinterError) -> String {
        fatalError("Not Implemented")
    }
}

public struct ByteArrayPrinter: ParsablePrinter {
    public func print(_: PrinterIntel) throws(ParsablePrinterError) -> [UInt8] {
        fatalError("Not Implemented")
    }
}

public extension ParsablePrinter where Self == HexStringPrinter {
    static var hexString: Self {
        HexStringPrinter()
    }
}

public extension ParsablePrinter where Self == ByteArrayPrinter {
    static var byteArray: Self {
        ByteArrayPrinter()
    }
}

#if canImport(Foundation)
    import Foundation

    public struct DataPrinter: ParsablePrinter {
        public func print(_: PrinterIntel) throws(ParsablePrinterError) -> Data {
            fatalError("Not Implemented")
        }
    }

    public extension ParsablePrinter where Self == DataPrinter {
        static var data: Self {
            DataPrinter()
        }
    }
#endif
