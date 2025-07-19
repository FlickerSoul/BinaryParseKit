// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "BinaryParseKit",
    platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v11), .tvOS(.v18), .visionOS(.v2)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BinaryParseKit",
            targets: ["BinaryParseKit"]
        ),
        .executable(
            name: "BinaryParseKitClient",
            targets: ["BinaryParseKitClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/apple/swift-binary-parsing", .upToNextMinor(from: "0.0.1")),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMinor(from: "1.1.0")
        ),
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
            ]
        ),
        .target(
            name: "BinaryParseKitCommons",
            dependencies: [.product(name: "BinaryParsing", package: "swift-binary-parsing")],
            swiftSettings: [.enableExperimentalFeature("LifetimeDependence"), .strictMemorySafety()]
        ),
        .target(name: "BinaryParseKit", dependencies: ["BinaryParseKitMacros"], swiftSettings: [
            .enableExperimentalFeature("LifetimeDependence"),
            .strictMemorySafety(),
        ]),
        .executableTarget(
            name: "BinaryParseKitClient",
            dependencies: [
                "BinaryParseKit",
                "BinaryParseKitCommons",
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("LifetimeDependence"),
                .strictMemorySafety(),
            ]
        ),
        .testTarget(
            name: "BinaryParseKitMacroTests",
            dependencies: [
                "BinaryParseKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "BinaryParseKitTests",
            dependencies: [
                "BinaryParseKit",
                "BinaryParseKitCommons",
            ]
        ),
    ]
)
