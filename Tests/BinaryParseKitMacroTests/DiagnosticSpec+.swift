//
//  DiagnosticSpec+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//
import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport

extension DiagnosticSpec {
    init(
        diagnostic: DiagnosticMessage,
        line: Int,
        column: Int,
        highlights: [String]? = nil,
        notes: [NoteSpec] = [],
        fixIts: [FixItSpec] = [],
        originatorFileID: StaticString = #fileID,
        originatorFile: StaticString = #filePath,
        originatorLine: UInt = #line,
        originatorColumn: UInt = #column,
    ) {
        self.init(
            id: diagnostic.diagnosticID,
            message: diagnostic.message,
            line: line,
            column: column,
            severity: diagnostic.severity,
            highlights: highlights,
            notes: notes,
            fixIts: fixIts,
            originatorFileID: originatorFileID,
            originatorFile: originatorFile,
            originatorLine: originatorLine,
            originatorColumn: originatorColumn,
        )
    }
}
