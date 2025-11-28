//
//  PrinterError.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//

public enum PrinterError: Swift.Error {
    /// Indicates that the construction of printer intel failed, with the underlying error provided.
    case intelConstructionFailed(underlying: any Error)
    /// Indicates that the provided type does not conform to ``Printable``.
    case notPrintable(type: Any.Type)
    /// Indicates that error is thrown by underling printer during printing process.
    case printingError(underlying: any Error)
}
