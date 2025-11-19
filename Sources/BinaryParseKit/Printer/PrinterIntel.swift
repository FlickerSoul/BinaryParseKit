//
//  PrinterIntel.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/15/25.
//
import BinaryParsing

/// An enumeration representing different types of printing instructions for binary data.
public enum PrinterIntel: Equatable {
    case `struct`(StructPrintIntel)
    case `enum`(EnumCasePrinterIntel)
    case builtIn(BuiltInPrinterIntel)
    case skip(SkipPrinterIntel)
}

public extension PrinterIntel {
    /// An instruction representing bytes skipped during parsing
    struct SkipPrinterIntel: Equatable {
        public typealias ByteCount = Int

        public let byteCount: ByteCount

        public init(byteCount: ByteCount) {
            self.byteCount = byteCount
        }
    }
}

public extension PrinterIntel {
    /// An instruction representing built-in or custom types
    struct BuiltInPrinterIntel: Equatable {
        // FIXME: better representation for big/little endian and invariant endianness?
        // FIXME: maybe use 3 fields: bytes, endianness, fixedEndianness
        /// - Note: bytes in big endian, which will be flipped if endianness is little
        public let bytes: [UInt8]
        /// - Note: if true, `bytes` won't be flipped even if in little endian
        public let fixedEndianness: Bool

        public init(
            bytes: [UInt8],
            fixedEndianness: Bool = false,
        ) {
            self.bytes = bytes
            self.fixedEndianness = fixedEndianness
        }
    }
}

public extension PrinterIntel {
    /// An instruction representing a struct field or an enum associated value
    struct FieldPrinterIntel: Equatable {
        public typealias ByteCount = Int

        // TODO: add field name and type metadata?

        /// The number of bytes occupied by this field, if known
        ///
        /// - Note: In the case of ``ByteArrayPrinter``,  it will be used to trim the byte array represented in
        /// ``PrinterIntel/FieldPrinterIntel/intel``
        public let byteCount: ByteCount?
        /// The endianness to use when printing this field, if known
        ///
        /// - Note: In the case of ``ByteArrayPrinter``, it will be used to determine how to interpret the byte array
        /// represented in ``PrinterIntel/FieldPrinterIntel/intel`` **ONLY** when it is ``PrinterIntel/builtIn(_:)``
        public let endianness: Endianness?
        /// The instruction for this field
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
    /// An instruction representing a struct with multiple fields
    struct StructPrintIntel: Equatable {
        /// The fields of the struct
        /// Each representing a field in the struct
        public let fields: [FieldPrinterIntel]

        public init(fields: [FieldPrinterIntel]) {
            self.fields = fields
        }
    }
}

public extension PrinterIntel {
    /// An instruction representing an enum case with possible associated values
    struct EnumCasePrinterIntel: Equatable {
        /// The type of parsing to perform for this enum case
        public enum CaseParseType {
            case match
            case matchAndTake
            case matchDefault
        }

        // TODO: add enum case metadata?

        /// The bytes used in match macro whose type is specified in ``PrinterIntel/EnumCasePrinterIntel/CaseParseType``
        public let bytes: [UInt8]
        /// The type of parsing performed for this enum case
        public let parseType: CaseParseType
        /// The associated values of the enum case, if any
        public let fields: [FieldPrinterIntel]

        public init(
            bytes: [UInt8],
            parseType: CaseParseType,
            fields: [FieldPrinterIntel],
        ) {
            self.bytes = bytes
            self.parseType = parseType
            self.fields = fields
        }
    }
}
