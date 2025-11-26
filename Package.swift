// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "LyricsKit",
    platforms: [
        .macOS(.v12), // 稍微提升 macOS 版本要求以更好地支持 Vapor 的并发特性
    ],
    products: [
        .executable(
            name: "LyricsCLI",
            targets: ["LyricsCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ddddxxx/Regex", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/attaswift/BigInt", from: "5.6.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.9.0"),
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.5"),
        // 新增 Vapor 依赖
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.0"),
    ],
    targets: [
        .target(
            name: "LyricsCore",
            dependencies: [
                .product(name: "Regex", package: "Regex"),
            ]
        ),
        .target(
            name: "LyricsService",
            dependencies: [
                "LyricsCore",
                .product(name: "Regex", package: "Regex"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "SWCompression", package: "SWCompression"),
            ]
        ),
        .executableTarget(
            name: "LyricsCLI",
            dependencies: [
                "LyricsService", 
                "LyricsCore",
                // 添加 Vapor 模块
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "LyricsKitTests",
            dependencies: [
                "LyricsCore",
                "LyricsService",
            ]
        ),
    ]
)
