//
//  DataPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

import Foundation

public struct DataPrinter: ParsablePrinter {
    public func print(_ intel: PrinterIntel) throws(ParsablePrinterError) -> Data {
        try Data(ByteArrayPrinter().print(intel))
    }
}

public extension ParsablePrinter where Self == DataPrinter {
    static var data: Self {
        DataPrinter()
    }
}
