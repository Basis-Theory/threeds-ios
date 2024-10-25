// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThreeDS",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ThreeDS",
            targets: ["ThreeDS"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/unravelin/ravelin-3ds-sdk-ios-xcframework-distribution",
            from: "1.1.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "Ravelin3DS",
            url:
                "https://ravelin.mycloudrepo.io/public/repositories/threeds2service-ios/release/1.1.2/Ravelin3DS.xcframework.zip",
            checksum: "c06a38d4644567baa5a86f8d457f9c4b2809b246247b23de894856f157747863"
        ),
        .target(
            name: "ThreeDS",
            dependencies: ["Ravelin3DS"]
        ),
    ]
)
