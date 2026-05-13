// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Cheetos",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Cheetos", targets: ["Cheetos"])
    ],
    targets: [
        .executableTarget(
            name: "Cheetos",
            resources: [.copy("Resources/cheatsheets")]
        )
    ]
)
