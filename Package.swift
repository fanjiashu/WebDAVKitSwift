// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "WebDavKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "WebDavKit",
            targets: ["WebDavKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "7.0.2"),
    ],
    targets: [
        .target(
            name: "WebDavKit",
            dependencies: ["SWXMLHash"],
            path: "Sources"
        ),
        .testTarget(
            name: "WebDavKitTests",
            dependencies: ["WebDavKit"],
            path: "Tests"
        ),
    ]
)


