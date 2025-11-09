//
//  NoteSpec+.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/8/25.
//
import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport

extension NoteSpec {
    init(
        note: NoteMessage,
        line: Int,
        column: Int,
        originatorFileID: StaticString = #fileID,
        originatorFile: StaticString = #filePath,
        originatorLine: UInt = #line,
        originatorColumn: UInt = #column,
    ) {
        self.init(
            message: note.message,
            line: line,
            column: column,
            originatorFileID: originatorFileID,
            originatorFile: originatorFile,
            originatorLine: originatorLine,
            originatorColumn: originatorColumn,
        )
    }
}
