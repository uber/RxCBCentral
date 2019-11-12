// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxCBCentral",
    platforms: [
        SupportedPlatform.iOS(.v8),
        SupportedPlatform.macOS("10.13")
    ],
    products: [
        .library(name: "RxCBCentral", targets: ["RxCBCentral"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/RxSwiftCommunity/RxOptional", .upToNextMajor(from: "4.1.0"))
    ],
    targets: [
        .target(
            name: "RxCBCentral",
            dependencies: [
                "RxSwift",
                "RxOptional",
            ],
            path: ".",
            exclude: [
                "ExampleApp",
                "Tests"
            ]
        ),
        .testTarget(
            name: "RxCBCentralTests",
            dependencies: ["RxCBCentral"]),
    ],
    swiftLanguageVersions: [.v5]
)
