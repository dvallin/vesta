// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Vesta",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Vesta",
            targets: ["Vesta"]
        )
    ],
    targets: [
        .target(
            name: "Vesta",
            path: "Vesta",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "VestaTests",
            dependencies: ["Vesta"],
            path: "VestaTests"
        ),
        .testTarget(
            name: "VestaUITests",
            dependencies: ["Vesta"],
            path: "VestaUITests"
        ),
    ]
)
