//
//  TestFailureLocation+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 7/17/25.
//
import SwiftSyntaxMacrosGenericTestSupport
import Testing

extension TestFailureLocation {
    var sourceLocation: Testing.SourceLocation {
        Testing.SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
    }
}
