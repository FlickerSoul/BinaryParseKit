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
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "BinaryParseKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "BinaryParsing", package: "swift-binary-parsing"),
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "BinaryParseKit", dependencies: ["BinaryParseKitMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "BinaryParseKitClient", dependencies: ["BinaryParseKit"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "BinaryParseKitTests",
            dependencies: [
                "BinaryParseKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
