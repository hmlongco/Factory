// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FactoryKit",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .tvOS(.v13),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FactoryKit",
            targets: ["FactoryKit"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FactoryKit",
            dependencies: [],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "FactoryTests",
            dependencies: ["FactoryKit"]
        )
    ],
    swiftLanguageVersions: [
        .v5, .version("6")
    ]
)
