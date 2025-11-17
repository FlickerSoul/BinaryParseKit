//
//  PrinterIntel.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/15/25.
//
import BinaryParsing

public enum PrinterIntel {
    case `struct`(StructPrintIntel)
    case `enum`(EnumCasePrinterIntel)
    case builtIn(BuiltInPrinterIntel)
    case skip(SkipPrinterIntel)
}

public struct SkipPrinterIntel {
    public let byteCount: Int

    public init(byteCount: Int) {
        self.byteCount = byteCount
    }
}

public struct BuiltInPrinterIntel {
    public let bytes: [UInt8]

    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
}

public struct FieldPrinterIntel {
    public let byteCount: Int?
    public let bigEndian: Endianness?
    public let intel: PrinterIntel

    public init(
        byteCount: Int?,
        bigEndian: Endianness?,
        intel: PrinterIntel,
    ) {
        self.byteCount = byteCount
        self.bigEndian = bigEndian
        self.intel = intel
    }
}

public struct StructPrintIntel {
    public let fields: [FieldPrinterIntel]

    public init(fields: [FieldPrinterIntel]) {
        self.fields = fields
    }
}

public struct EnumCasePrinterIntel {
    public enum CaseParseType {
        case match
        case matchAndTake
        case matchDefault
    }

    public let enumCaseName: String
    public let bytes: [UInt8]
    public let parseType: CaseParseType
    public let fields: [FieldPrinterIntel]

    public init(
        enumCaseName: String,
        bytes: [UInt8],
        parseType: CaseParseType,
        fields: [FieldPrinterIntel],
    ) {
        self.enumCaseName = enumCaseName
        self.bytes = bytes
        self.parseType = parseType
        self.fields = fields
    }
}
