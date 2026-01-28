// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import class Foundation.ProcessInfo
import PackageDescription

private let enableBenchmark = ProcessInfo.processInfo.environment["ENABLE_BENCHMARK"]

let package = Package(
    name: "BinaryParseKit",
    platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BinaryParseKit",
            targets: ["BinaryParseKit"],
        ),
        .executable(
            name: "BinaryParseKitClient",
            targets: ["BinaryParseKitClient"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: "602.0.0")),
        .package(url: "https://github.com/apple/swift-binary-parsing.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.6.4"),
        .package(url: "https://github.com/stackotter/swift-macro-toolkit.git", from: "0.8.0"),
    ],
    targets: [
        .macro(
            name: "BinaryParseKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
                .product(name: "Collections", package: "swift-collections"),
                .target(name: "BinaryParseKitCommons"),
                .product(name: "MacroToolkit", package: "swift-macro-toolkit"),
            ],
        ),
        .target(
            name: "BinaryParseKitCommons",
            swiftSettings: [
                .enableExperimentalFeature("LifetimeDependence"),
                .enableExperimentalFeature("Lifetimes"),
                .strictMemorySafety(),
            ],
        ),
        .target(
            name: "BinaryParseKit",
            dependencies: [
                "BinaryParseKitMacros",
                "BinaryParseKitCommons",
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("LifetimeDependence"),
                .enableExperimentalFeature("Lifetimes"),
                .strictMemorySafety(),
            ],
        ),
        .executableTarget(
            name: "BinaryParseKitClient",
            dependencies: [
                "BinaryParseKit",
            ],
            swiftSettings: [
                .enableExperimentalFeature("LifetimeDependence"),
                .enableExperimentalFeature("Lifetimes"),
                .strictMemorySafety(),
            ],
        ),
        .testTarget(
            name: "BinaryParseKitMacroTests",
            dependencies: [
                "BinaryParseKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                "BinaryParseKitCommons",
            ],
        ),
        .testTarget(
            name: "BinaryParseKitTests",
            dependencies: [
                "BinaryParseKit",
            ],
        ),

    ],
    swiftLanguageModes: [.v6],
)

if enableBenchmark == "1" || enableBenchmark == "true" {
    package.dependencies.append(
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.29.7"),
    )
    package.targets.append(contentsOf: [
        .target(
            name: "BenchmarkTypes",
            dependencies: [
                "BinaryParseKit",
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "Benchmarks/BenchmarkTypes",
        ),
        .testTarget(
            name: "BenchmarkTypesTests",
            dependencies: [
                "BenchmarkTypes",
            ],
            path: "Benchmarks/BenchmarkTypesTests",
        ),
        .executableTarget(
            name: "ParsingBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "BenchmarkPlugin", package: "package-benchmark"),
                "BinaryParseKit",
                "BenchmarkTypes",
            ],
            path: "Benchmarks/ParsingBenchmarks",
        ),
        .executableTarget(
            name: "PrintingBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "BenchmarkPlugin", package: "package-benchmark"),
                "BinaryParseKit",
                "BenchmarkTypes",
            ],
            path: "Benchmarks/PrintingBenchmarks",
        ),
    ])
}
