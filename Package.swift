// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcodeGenericSonarCoverage",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "XcodeGenericSonarCoverage",
            targets: ["XcodeGenericSonarCoverage"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "5.1.0-beta.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "XcodeGenericSonarCoverage",
            dependencies: ["SwiftShell"]),
        .testTarget(
            name: "XcodeGenericSonarCoverageTests",
            dependencies: ["XcodeGenericSonarCoverage"]),
    ]
)
