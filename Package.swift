// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacTextify", platforms: [.macOS(.v14)],
    products: [.executable(name: "mactextify", targets: ["MacTextify"])],
    targets: [
        .target(name: "OCRCore"),
        .executableTarget(name: "MacTextify", dependencies: ["OCRCore"]),
        .testTarget(name: "OCRCoreTests", dependencies: ["OCRCore"])
    ]
)
