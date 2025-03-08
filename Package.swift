// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AmethystAuthenticatorCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AmethystAuthenticatorCore",
                 targets: ["AmethystAuthenticatorCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", exact: .init(4, 2, 2)),
        .package(url: "https://github.com/lachlanbell/SwiftOTP.git", exact: .init(3, 0, 2)),
    ],
    targets: [
        .target(name: "AmethystAuthenticatorCore", dependencies: [
            .byName(name: "KeychainAccess"),
            .byName(name: "SwiftOTP")
        ]),
        .testTarget(name: "Tests", dependencies: [
            .byName(name: "AmethystAuthenticatorCore"),
            .byName(name: "KeychainAccess")
        ], path: "Tests")
    ]
)
