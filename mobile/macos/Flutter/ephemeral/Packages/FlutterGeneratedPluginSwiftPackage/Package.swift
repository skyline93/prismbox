// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "wakelock_plus", path: "../.packages/wakelock_plus"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation"),
        .package(name: "sqlite3_flutter_libs", path: "../.packages/sqlite3_flutter_libs"),
        .package(name: "photo_manager", path: "../.packages/photo_manager"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation"),
        .package(name: "local_auth_darwin", path: "../.packages/local_auth_darwin"),
        .package(name: "flutter_udid", path: "../.packages/flutter_udid"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "wakelock-plus", package: "wakelock_plus"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "sqlite3-flutter-libs", package: "sqlite3_flutter_libs"),
                .product(name: "photo-manager", package: "photo_manager"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "local-auth-darwin", package: "local_auth_darwin"),
                .product(name: "flutter-udid", package: "flutter_udid"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin")
            ]
        )
    ]
)
