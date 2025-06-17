// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Factory",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v8),
        .visionOS(.v1),
        .macCatalyst(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FactoryKit",
            targets: ["FactoryKit"]
        ),
        .library(
            name: "FactoryMacros",
            targets: ["FactoryKit", "FactoryMacros"]
        ),
        .library(
            name: "FactoryTesting",
            targets: ["FactoryTesting"]
        ),
        .executable(
            name: "FactoryMacrosClient",
            targets: ["FactoryMacrosClient"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "601.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FactoryKit",
            dependencies: [],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: FactorySwiftSetting.common
        ),
        .target(
            name: "FactoryMacros",
            dependencies: [
                "FactoryKit",
                "FactoryMacrosImplementation",
            ],
            swiftSettings: FactorySwiftSetting.common
        ),
        .macro(
            name: "FactoryMacrosImplementation",
            dependencies: [
                "FactoryKit",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            swiftSettings: FactorySwiftSetting.common
        ),
        .executableTarget(
            name: "FactoryMacrosClient",
            dependencies: [
                "FactoryKit",
                "FactoryMacros",
            ],
            swiftSettings: FactorySwiftSetting.common
        ),
        .target(
            name: "FactoryTesting",
            dependencies: [
                "FactoryKit"
            ],
            swiftSettings: FactorySwiftSetting.common
        ),
        .testTarget(
            name: "FactoryTests",
            dependencies: [
                "FactoryMacros",
                "FactoryTesting"
            ],
            swiftSettings: FactorySwiftSetting.common
        )
    ],
    swiftLanguageModes: [
        .version("6")
    ]
)

enum FactorySwiftSetting {
    static let common: [SwiftSetting] = [
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
