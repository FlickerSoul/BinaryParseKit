//
//  String+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//

import BinaryParseKit
import BinaryParsing
import Foundation

extension String: SizedParsable {
    public init(parsing input: inout BinaryParsing.ParserSpan, byteCount: Int) throws {
        try self.init(parsingUTF8: &input, count: byteCount)
    }
}

extension String: Printable {
    public func printerIntel() -> PrinterIntel {
        .builtIn(
            .init(
                bytes: .init(data(using: .utf8) ?? Data()),
                fixedEndianness: true,
            ),
        )
    }
}
