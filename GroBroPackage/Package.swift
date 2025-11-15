// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GroBroFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GroBroFeature",
            targets: ["GroBroFeature"]
        ),
        .library(
            name: "GroBroDomain",
            targets: ["GroBroDomain"]
        ),
        .library(
            name: "GroBroPersistence",
            targets: ["GroBroPersistence"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GroBroFeature",
            dependencies: ["GroBroDomain"]
        ),
        .target(
            name: "GroBroDomain",
            dependencies: ["GroBroPersistence"]
        ),
        .target(
            name: "GroBroPersistence",
            resources: [.process("GroBroModel.xcdatamodeld")]
        ),
        .testTarget(
            name: "GroBroFeatureTests",
            dependencies: [
                "GroBroFeature"
            ]
        ),
        .testTarget(
            name: "GroBroDomainTests",
            dependencies: [
                "GroBroDomain",
                "GroBroPersistence"
            ]
        ),
        .testTarget(
            name: "GroBroPersistenceTests",
            dependencies: [
                "GroBroPersistence"
            ]
        ),
    ]
)
