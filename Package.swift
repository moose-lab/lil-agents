// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LilAgents",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "LilAgents",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "LilAgents",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "LilAgents.entitlements",
                "menuicon.png",
                "menuicon-2x.png",
            ],
            resources: [
                .copy("Sounds"),
                .copy("walk-bruce-01.mov"),
                .copy("walk-jazz-01.mov"),
                .copy("walk-luna-01.mov"),
            ]
        ),
    ]
)
