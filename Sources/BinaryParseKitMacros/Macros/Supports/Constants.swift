//
//  Constants.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/6/25.
//
struct PackageMember: CustomStringConvertible {
    let package: String
    let name: String

    fileprivate init(package: String = Constants.packageName, name: String) {
        self.package = package
        self.name = name
    }

    var canonicalName: String {
        "\(package).\(name)"
    }

    var description: String {
        canonicalName
    }
}

enum Constants {
    static let packageName = "BinaryParseKit"
}

extension Constants {
    enum Protocols {
        static let parsableProtocol = PackageMember(name: "Parsable")
        static let sizedParsableProtocol = PackageMember(name: "SizedParsable")
        static let endianParsableProtocol = PackageMember(name: "EndianParsable")
        static let endianSizedParsableProtocol = PackageMember(name: "EndianSizedParsable")
        static let expressibleByParsingProtocol = PackageMember(name: "ExpressibleByParsing")
        static let matchableProtocol = PackageMember(name: "Matchable")
        static let printableProtocol = PackageMember(name: "Printable")
    }
}

extension Constants {
    enum UtilityFunctions {
        static let matchBytes = PackageMember(name: "__match")
        static let matchLength = PackageMember(name: "__matchLength")
        static let assertParsable = PackageMember(name: "__assertParsable")
        static let assertSizedParsable = PackageMember(name: "__assertSizedParsable")
        static let assertEndianParsable = PackageMember(name: "__assertEndianParsable")
        static let assertEndianSizedParsable = PackageMember(name: "__assertEndianSizedParsable")
        static let getPrintIntel = PackageMember(name: "__getPrinterIntel")
    }
}

extension Constants {
    enum BinaryParserKitError {
        static let failedToParse = PackageMember(name: "BinaryParserKitError.failedToParse")
    }
}

extension Constants {
    enum BinaryParsing {
        private static let packageName = "BinaryParsing"
        static let parserSpan = PackageMember(package: packageName, name: "ParserSpan")
        static let thrownParsingError = PackageMember(package: packageName, name: "ThrownParsingError")
    }
}

extension Constants {
    enum PrinterIntel {
        static let structPrintIntel = PackageMember(name: "StructPrintIntel")
        static let enumCasePrinterIntel = PackageMember(name: "EnumCasePrinterIntel")
    }
}

extension Constants {
    enum Swift {
        private static let packageName = "Swift"
        static let byteCountType = PackageMember(package: packageName, name: "Int")
    }
}
