// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SubTrackSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SubTrackSDK",
            targets: ["SubTrackSDK"]
        ),
    ],
    targets: [
        .target(
            name: "SubTrackSDK",
            dependencies: [],
            path: "Sources/SubTrackSDK"
        ),
    ]
)
