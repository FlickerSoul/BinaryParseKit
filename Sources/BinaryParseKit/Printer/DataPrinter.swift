//
//  DataPrinter.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/17/25.
//

import Foundation

/// A printer that outputs data as `Data`.
public struct DataPrinter: Printer {
    public func print(_ intel: PrinterIntel) throws -> Data {
        try Data(ByteArrayPrinter().print(intel))
    }
}

public extension Printer where Self == DataPrinter {
    static var data: Self {
        DataPrinter()
    }
}
