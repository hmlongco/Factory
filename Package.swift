// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if swift(<6.0)
private let importOpenSourceSwiftTesting = true
#else
private let importOpenSourceSwiftTesting = false
#endif

/// Only clone swift-testing from Github when Xcode doesn't support necessary features
private func getOpenSourceSwiftTestingPackageDependency() -> [Package.Dependency] {
    guard importOpenSourceSwiftTesting else {
        return []
    }
    
    return [.package(url: "https://github.com/swiftlang/swift-testing", from: "6.1.0")]
}

/// Only link swift-testing from Github when Xcode doesn't support necessary features
private func getOpenSourceSwiftTestingPackageTarget() -> [Target.Dependency] {
    guard importOpenSourceSwiftTesting else {
        return []
    }
    
    return [.product(name: "Testing", package: "swift-testing")]
}

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
        
        // Only clone swift-testing if required
    ] + getOpenSourceSwiftTestingPackageDependency(),
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Factory",
            dependencies: [],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [
//                .unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"], .when(configuration: .debug)),
//                .unsafeFlags(["-enable-library-evolution"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "FactoryTesting",
            
            // Only link swift-testing if required
            dependencies: ["Factory"] + getOpenSourceSwiftTestingPackageTarget()
        ),
        .testTarget(
            name: "FactoryTests",
            
            // Only link swift-testing if required
            dependencies: ["Factory", "FactoryTesting"] + getOpenSourceSwiftTestingPackageTarget()
        )
    ],
    swiftLanguageVersions: [
        .version("6"), .v5
    ]
)
