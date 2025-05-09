// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Factory",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
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
        .library(
            name: "Factory",
            targets: ["Factory"]
        ),
        .library(
            name: "FactoryTesting",
            targets: ["FactoryTesting"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Factory",
            dependencies: [],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [
//                .unsafeFlags(["-enable-library-evolution"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "FactoryKit",
            dependencies: [],
            path: "Sources/FactoryKit",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "FactoryTesting",
            dependencies: ["FactoryKit"]
        ),
        .testTarget(
            name: "FactoryTests",
            dependencies: ["FactoryKit", "FactoryTesting"]
        )
    ],
    swiftLanguageVersions: [
        .version("6"), .v5
    ]
)

#if compiler(>=6)
for target in package.targets where target.type != .system {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(contentsOf: [
        .enableExperimentalFeature("StrictConcurrency"),
    ])
}
#endif
