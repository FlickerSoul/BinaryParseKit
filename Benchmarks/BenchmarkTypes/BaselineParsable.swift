//
//  BaselineParsable.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 1/6/26.
//

import Foundation

/// Protocol for types that provide a baseline parsing implementation for benchmarking.
public protocol BaselineParsable {
    /// Parses the type from raw data without bounds checking.
    /// Used as a baseline for performance comparison in benchmarks.
    static func parseBaseline(_ data: Data) -> Self
}
