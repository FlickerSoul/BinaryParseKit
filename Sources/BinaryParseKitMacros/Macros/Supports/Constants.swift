//
//  Constants.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/6/25.
//
struct ProtocolName: CustomStringConvertible {
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
    static let parsableProtocol = ProtocolName(name: "Parsable")
    static let sizedParsableProtocol = ProtocolName(name: "SizedParsable")
    static let endianParsableProtocol = ProtocolName(name: "EndianParsable")
    static let endianSizedParsableProtocol = ProtocolName(name: "EndianSizedParsable")
    static let expressibleByParsingProtocol = ProtocolName(name: "ExpressibleByParsing")
}
