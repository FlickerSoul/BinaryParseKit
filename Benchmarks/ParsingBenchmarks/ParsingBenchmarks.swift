//
//  ParsingBenchmarks.swift
//  BinaryParseKit
//
//  Benchmarks for binary parsing performance (enum, struct, bitmask).
//
// swiftlint:disable force_try

import Benchmark
import BinaryParseKit
import Foundation

let benchmarks: @Sendable () -> Void = {
    // Configure default settings for parsing benchmarks
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .cpuTotal, .throughput, .mallocCountTotal],
        warmupIterations: 100,
        scalingFactor: .kilo,
        maxDuration: .seconds(5),
        maxIterations: 1_000_000,
    )

    // MARK: - Enum Parsing Benchmarks

    let simpleEnumData = Data([0x01])
    let complexEnumData = Data([0x03, 0x12, 0x34, 0x56, 0x78])

    Benchmark("Parse Simple Enum") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkEnumSimple(parsing: simpleEnumData))
        }
    }

    Benchmark("Parse Simple Enum (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkEnumSimple.parseBaseline(simpleEnumData))
        }
    }

    Benchmark("Parse Complex Enum with Associated Values") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkEnumComplex(parsing: complexEnumData))
        }
    }

    Benchmark("Parse Complex Enum with Associated Values (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkEnumComplex.parseBaseline(complexEnumData))
        }
    }

    // MARK: - Struct Parsing Benchmarks

    let simpleStructData = Data([0x12, 0x34, 0x56, 0x78])
    let complexStructData = Data([
        0x89, 0x50, 0x4E, 0x47, // magic (BE)
        0x00, 0x00, // skip 2 bytes
        0x01, 0x00, // version (LE)
        0x00, 0x00, 0x00, 0x00, 0x5F, 0x5E, 0x10, 0x00, // timestamp (BE)
        0x0F, 0x00, // flags (LE)
    ])

    Benchmark("Parse Simple Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkStructSimple(parsing: simpleStructData))
        }
    }

    Benchmark("Parse Simple Struct (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkStructSimple.parseBaseline(simpleStructData))
        }
    }

    Benchmark("Parse Complex Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkStructComplex(parsing: complexStructData))
        }
    }

    Benchmark("Parse Complex Struct (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkStructComplex.parseBaseline(complexStructData))
        }
    }

    // MARK: - Bitmask Parsing Benchmarks

    let simpleBitmaskData = Data([0xA3])
    let simpleBitmaskBits: UInt8 = 0b1010_0011
    let complexBitmaskData = Data([0xAB, 0xCD, 0xEF, 0x12])
    let complexBitmaskBits: UInt32 = 0xABCD_EF12

    Benchmark("Parse Simple Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkBitmaskSimple(bits: simpleBitmaskBits))
        }
    }

    Benchmark("Parse Simple Bitmask (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkBitmaskSimple.parseBaseline(simpleBitmaskData))
        }
    }

    Benchmark("Parse Complex Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkBitmaskComplex(bits: complexBitmaskBits))
        }
    }

    Benchmark("Parse Complex Bitmask (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkBitmaskComplex.parseBaseline(complexBitmaskData))
        }
    }

    // MARK: - Comparative Benchmarks (Different Data Sizes)

    let smallData = Data([0x01])
    let mediumData = Data(repeating: 0xAB, count: 64)
    let largeData = Data(repeating: 0xCD, count: 1024)

    Benchmark("Parse Enum - Small Data") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BenchmarkEnumSimple(parsing: smallData))
        }
    }

    Benchmark("Parse Enum - Small Data (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BenchmarkEnumSimple.parseBaseline(smallData))
        }
    }

    // MARK: - Endianness Benchmarks

    let endianTestData = Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])

    Benchmark("Parse Big Endian Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! BigEndianStruct(parsing: endianTestData))
        }
    }

    Benchmark("Parse Big Endian Struct (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(BigEndianStruct.parseBaseline(endianTestData))
        }
    }

    Benchmark("Parse Little Endian Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! LittleEndianStruct(parsing: endianTestData))
        }
    }

    Benchmark("Parse Little Endian Struct (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(LittleEndianStruct.parseBaseline(endianTestData))
        }
    }

    // MARK: - Non-Byte-Aligned Bitmask Benchmarks

    let nonAlignedData = Data([0xAC, 0xC0])
    let nonAlignedBits: UInt16 = 0b1010_1100_1100_0000

    Benchmark("Parse Non-Byte-Aligned Bitmask (10 bits)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! NonByteAlignedBitmask(bits: nonAlignedBits))
        }
    }

    Benchmark("Parse Non-Byte-Aligned Bitmask (10 bits) (Baseline)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(NonByteAlignedBitmask.parseBaseline(nonAlignedData))
        }
    }
}

// swiftlint:enable force_try
