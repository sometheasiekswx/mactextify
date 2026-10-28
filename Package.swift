// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacTextify", platforms: [.macOS(.v14)],
    products: [.executable(name: "mactextify", targets: ["MacTextify"]), .executable(name: "MacTextifyApp", targets: ["MacTextifyApp"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.1")],
    targets: [
        .target(name: "OCRCore"),
        .target(name: "UpdateSupport"),
        .testTarget(name: "UpdateSupportTests", dependencies: ["UpdateSupport"]),
        .executableTarget(name: "MacTextifyApp", dependencies: ["OCRCore", "UpdateSupport", .product(name: "Sparkle", package: "Sparkle")], linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
        .executableTarget(name: "MacTextify", dependencies: ["OCRCore"]),
        .testTarget(name: "OCRCoreTests", dependencies: ["OCRCore"])
    ]
)
