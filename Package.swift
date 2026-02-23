// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableUpcomingFeature("RegionBasedIsolation"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
    .enableUpcomingFeature("DisableOutwardActorIsolation"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .swiftLanguageMode(.v6),
]

let package = Package(
    name: "MathViews",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
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
            ],
            swiftSettings: upcomingFeatures),
        .testTarget(
            name: "MathViewsTests",
            dependencies: ["MathViews"],
            swiftSettings: upcomingFeatures),
    ]
)
