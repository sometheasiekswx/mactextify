// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotOCR", platforms: [.macOS(.v14)],
    products: [.executable(name: "screenshot-ocr", targets: ["ScreenshotOCR"])],
    targets: [
        .target(name: "OCRCore"),
        .executableTarget(name: "ScreenshotOCR", dependencies: ["OCRCore"]),
        .testTarget(name: "OCRCoreTests", dependencies: ["OCRCore"])
    ]
)
