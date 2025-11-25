// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleanShot",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CleanShotApp", targets: ["CleanShotApp"])
    ],
    targets: [
        .executableTarget(
            name: "CleanShotApp",
            path: "Sources/CleanShotApp"
        )
    ]
)
