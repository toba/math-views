// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MathViews",
    defaultLocalization: "en",
    platforms: [.iOS("11.0"), .macOS("12.0")],
    products: [
        .library(
            name: "MathViews",
            targets: ["MathViews"]),
    ],
    targets: [
        .target(
            name: "MathViews",
            dependencies: [],
            resources: [
                .copy("mathFonts.bundle")
            ]),
        .testTarget(
            name: "MathViewsTests",
            dependencies: ["MathViews"]),
    ]
)
