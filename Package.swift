// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MessagePackKit",
    platforms: [
        .iOS(.v15), .macOS(.v12), .tvOS(.v15)
    ],
    products: [
        .library(name: "MessagePackKit", targets: ["MessagePackKit"])
    ],
    targets: [
        .target(
            name: "MessagePackKit",
            dependencies: [],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]),
        .testTarget(name: "MessagePackKitTests", dependencies: ["MessagePackKit"]),
    ]
)
