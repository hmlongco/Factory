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
            targets: ["FactoryMacros"]
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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FactoryKit",
            dependencies: [],
            path: "Sources/FactoryKit",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: .commonSettings
        ),
        .target(
            name: "FactoryMacros",
            dependencies: [
                "FactoryKit",
                "FactoryMacrosImplementation",
            ],
            path: "Sources/FactoryMacros",
            swiftSettings: .commonSettings
        ),
        .macro(
            name: "FactoryMacrosImplementation",
            dependencies: [
                "FactoryKit",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/FactoryMacrosImplementation",
            swiftSettings: .commonSettings
        ),
        .executableTarget(
            name: "FactoryMacrosClient",
            dependencies: [
                "FactoryKit",
                "FactoryMacros",
            ],
            path: "Sources/FactoryMacrosClient",
            swiftSettings: .commonSettings
        ),
        .target(
            name: "FactoryTesting",
            dependencies: [
                "FactoryKit"
            ],
            path: "Sources/FactoryTesting",
            swiftSettings: .commonSettings
        ),
        .testTarget(
            name: "FactoryTests",
            dependencies: [
                "FactoryMacros",
                "FactoryTesting"
            ],
            swiftSettings: .commonSettings
        )
    ],
    swiftLanguageModes: [
        .version("6")
    ]
)

extension [SwiftSetting] {
    static let commonSettings: [SwiftSetting] = [
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
