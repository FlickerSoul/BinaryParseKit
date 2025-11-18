//
//  PrinterIntel.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/15/25.
//
import BinaryParsing

public enum PrinterIntel: Equatable {
    case `struct`(StructPrintIntel)
    case `enum`(EnumCasePrinterIntel)
    case builtIn(BuiltInPrinterIntel)
    case skip(SkipPrinterIntel)
}

public extension PrinterIntel {
    struct SkipPrinterIntel: Equatable {
        public typealias ByteCount = Int

        public let byteCount: ByteCount

        public init(byteCount: ByteCount) {
            self.byteCount = byteCount
        }
    }
}

public extension PrinterIntel {
    struct BuiltInPrinterIntel: Equatable {
        /// - Note: bytes in big endian
        public let bytes: [UInt8]
        /// - Note: if true, `bytes` won't be flipped based on endianness
        public let fixedEndianness: Bool

        public init(bytes: [UInt8], fixedEndianness: Bool = false) {
            self.bytes = bytes
            self.fixedEndianness = fixedEndianness
        }
    }
}

public extension PrinterIntel {
    struct FieldPrinterIntel: Equatable {
        public typealias ByteCount = Int

        public let byteCount: ByteCount?
        public let endianness: Endianness?
        public let intel: PrinterIntel

        public init(
            byteCount: ByteCount?,
            endianness: Endianness?,
            intel: PrinterIntel,
        ) {
            self.byteCount = byteCount
            self.endianness = endianness
            self.intel = intel
        }
    }
}

public extension PrinterIntel {
    struct StructPrintIntel: Equatable {
        public let fields: [FieldPrinterIntel]

        public init(fields: [FieldPrinterIntel]) {
            self.fields = fields
        }
    }
}

public extension PrinterIntel {
    struct EnumCasePrinterIntel: Equatable {
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
}
