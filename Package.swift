// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-posix",
    products: [
        .library(
            name: "POSIX Kernel",
            targets: ["POSIX Kernel"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-kernel-primitives.git", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-standards.git", from: "0.29.0")
    ],
    targets: [
        .target(
            name: "CPOSIXProcessShim",
            dependencies: []
        ),
        .target(
            name: "POSIX Primitives",
            dependencies: [
                .product(name: "Kernel Primitives", package: "swift-kernel-primitives")
            ]
        ),
        .target(
            name: "POSIX Kernel",
            dependencies: [
                .product(name: "Kernel Primitives", package: "swift-kernel-primitives"),
                .target(name: "CPOSIXProcessShim", condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS, .linux])),
                .target(name: "POSIX Primitives"),
            ]
        ),
        .testTarget(
            name: "POSIX Kernel Tests",
            dependencies: [
                "POSIX Kernel",
                .product(name: "Kernel Primitives Test Support", package: "swift-kernel-primitives"),
                .product(name: "StandardsTestSupport", package: "swift-standards")
            ],
            path: "Tests/POSIX Kernel Tests"
        ),
    ]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
