// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CleanSlate",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "CleanSlate", path: "Sources/CleanSlate")
    ]
)
