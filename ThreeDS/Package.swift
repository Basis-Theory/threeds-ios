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
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "Ravelin3DS",
            url: "https://ravelin.mycloudrepo.io/repositories/threeds2service-ios/release/1.1.1/Ravelin3DS.xcframework.zip",
            checksum: "18bc30fa06685bf3e129a12421a8fd5a6b5a29807f688f8a01ba4e30cca4fe0d"
        ),
        .target(
            name: "ThreeDS",
            dependencies: ["Ravelin3DS"]
        ),
    ]
)
