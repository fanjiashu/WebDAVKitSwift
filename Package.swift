// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "DAVKitSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "DAVKitSwift",
            targets: ["DAVKitSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "7.0.2"),
    ],
    targets: [
        .target(
            name: "DAVKitSwift",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "DAVKitSwiftTests",
            dependencies: ["DAVKitSwift"],
            path: "Tests"),
    ]
)

