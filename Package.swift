// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "PDVariableBlur",
    platforms: [
        .iOS(.v17),.macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PDVariableBlur",
            targets: ["PDVariableBlur"]),
        // Adding an executable product for the examples target allows Xcode
        // to generate a scheme that includes Example.swift for previews.
        .executable(
            name: "Examples",
            targets: ["Examples"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PDVariableBlur"),
        .executableTarget(
            name: "Examples",
            dependencies: ["PDVariableBlur"],
            path: "Examples"),

    ]
)
