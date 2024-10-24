// swift-tools-version: 5.9.1
import PackageDescription

let package = Package(
    name: "chatterbox",
    platforms: [
        .macOS(.v10_15) // Specify macOS 10.15 since I depend on the use of Task {}
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.10.0")
    ],
    targets: [
        .executableTarget(
            name: "chatterbox",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            path: "Sources"
        )
    ]
)
