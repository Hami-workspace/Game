// swift-tools-version: 5.8
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "TrafficRacer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .iOSApplication(
            name: "TrafficRacer",
            targets: ["App"],
            displayVersion: "1.0",
            bundleVersion: "1",
            iconAssetName: "AppIcon",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "App",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
