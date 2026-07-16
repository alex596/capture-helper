// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "capture_helper",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "capture-helper", targets: ["capture_helper"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "capture_helper",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
