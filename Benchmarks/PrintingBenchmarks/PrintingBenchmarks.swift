//
//  PrintingBenchmarks.swift
//  BinaryParseKit
//
//  Benchmarks for binary printing performance (enum, struct, bitmask).
//
// swiftlint:disable force_try

import Benchmark
import BinaryParseKit
import Foundation

let benchmarks: @Sendable () -> Void = {
    // Configure default settings for printing benchmarks
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .cpuTotal, .throughput, .mallocCountTotal],
        warmupIterations: 100,
        scalingFactor: .kilo,
        maxDuration: .seconds(5),
        maxIterations: 1_000_000,
    )

    // MARK: - Enum Printing Benchmarks

    let simpleEnum = PrintBenchmarkEnumSimple.first
    let complexEnum = PrintBenchmarkEnumComplex.withTwoValues(0x1234, 0x5678)

    Benchmark("Print Simple Enum") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleEnum.printParsed(printer: .data))
        }
    }

    Benchmark("Print Complex Enum with Associated Values") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexEnum.printParsed(printer: .data))
        }
    }

    Benchmark("Get PrinterIntel - Simple Enum") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleEnum.printerIntel())
        }
    }

    Benchmark("Get PrinterIntel - Complex Enum") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexEnum.printerIntel())
        }
    }

    // MARK: - Struct Printing Benchmarks

    let simpleStruct = PrintBenchmarkStructSimple(value: 0x1234_5678)
    let complexStruct = PrintBenchmarkStructComplex(
        magic: 0x8950_4E47,
        version: 0x0001,
        timestamp: 0x0000_0000_5F5E_1000,
        flags: 0x000F,
    )

    Benchmark("Print Simple Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleStruct.printParsed(printer: .data))
        }
    }

    Benchmark("Print Complex Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexStruct.printParsed(printer: .data))
        }
    }

    Benchmark("Get PrinterIntel - Simple Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleStruct.printerIntel())
        }
    }

    Benchmark("Get PrinterIntel - Complex Struct") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexStruct.printerIntel())
        }
    }

    // MARK: - Bitmask Printing Benchmarks

    let simpleBitmask = PrintBenchmarkBitmaskSimple(flag: 1, value: 0x23)
    let complexBitmask = PrintBenchmarkBitmaskComplex(
        flag1: 1,
        priority: 5,
        nibble: 11,
        byte: 0xCD,
        word: 0xEF12,
    )

    Benchmark("Print Simple Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleBitmask.printParsed(printer: .data))
        }
    }

    Benchmark("Print Complex Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexBitmask.printParsed(printer: .data))
        }
    }

    Benchmark("Get PrinterIntel - Simple Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleBitmask.printerIntel())
        }
    }

    Benchmark("Get PrinterIntel - Complex Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexBitmask.printerIntel())
        }
    }

    // MARK: - toRawBits Benchmarks

    Benchmark("toRawBits - Simple Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! simpleBitmask.toRawBits(bitCount: PrintBenchmarkBitmaskSimple.bitCount))
        }
    }

    Benchmark("toRawBits - Complex Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! complexBitmask.toRawBits(bitCount: PrintBenchmarkBitmaskComplex.bitCount))
        }
    }

    // MARK: - Round-Trip Benchmarks (Parse then Print)

    let roundTripEnumData = Data([0x03, 0x12, 0x34, 0x56, 0x78])
    let roundTripStructData = Data([0x12, 0x34, 0x56, 0x78])
    let roundTripBitmaskBits = RawBits(data: Data([0xA3]), size: 8)

    Benchmark("Round-Trip Enum (Parse + Print)") { benchmark in
        for _ in benchmark.scaledIterations {
            let parsed = try! PrintBenchmarkEnumComplex(parsing: roundTripEnumData)
            blackHole(try! parsed.printParsed(printer: .data))
        }
    }

    Benchmark("Round-Trip Struct (Parse + Print)") { benchmark in
        for _ in benchmark.scaledIterations {
            let parsed = try! PrintBenchmarkStructSimple(parsing: roundTripStructData)
            blackHole(try! parsed.printParsed(printer: .data))
        }
    }

    Benchmark("Round-Trip Bitmask (Parse + Print)") { benchmark in
        for _ in benchmark.scaledIterations {
            let parsed = try! PrintBenchmarkBitmaskSimple(bits: roundTripBitmaskBits)
            blackHole(try! parsed.printParsed(printer: .data))
        }
    }

    // MARK: - Non-Byte-Aligned Bitmask Printing

    let nonAlignedBitmask = NonByteAlignedPrintBitmask(first: 5, second: 12, third: 3)

    Benchmark("Print Non-Byte-Aligned Bitmask (10 bits)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! nonAlignedBitmask.printParsed(printer: .data))
        }
    }

    Benchmark("toRawBits - Non-Byte-Aligned Bitmask") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! nonAlignedBitmask.toRawBits(bitCount: NonByteAlignedPrintBitmask.bitCount))
        }
    }
}

// swiftlint:enable force_try
