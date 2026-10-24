// Run from the repository root: swift scripts/generate-app-icon.swift
// Native vector rendering at every icon size; no external dependencies.
import AppKit
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
func render(_ pixels: Int, dark: Bool) throws -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let c = context.cgContext
    c.scaleBy(x: CGFloat(pixels)/1024, y: CGFloat(pixels)/1024)
    c.translateBy(x: 0, y: 1024); c.scaleBy(x: 1, y: -1)
    let tile = CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824),
                      cornerWidth: 184, cornerHeight: 184, transform: nil)
    c.setFillColor(dark ? CGColor(gray: 0, alpha: 1) : CGColor(gray: 1, alpha: 1))
    c.addPath(tile); c.fillPath()
    c.setStrokeColor(CGColor(gray: dark ? 1 : 0, alpha: 0.12)); c.setLineWidth(2)
    c.addPath(tile); c.strokePath()
    // Center the original 202...404 by 65...265 mark, with ample tile padding.
    c.translateBy(x: 512 - 303*2.4, y: 512 - 165*2.4)
    c.scaleBy(x: 2.4, y: 2.4)
    c.setStrokeColor(dark ? CGColor(gray: 1, alpha: 1) : CGColor(gray: 0, alpha: 1))
    c.setLineWidth(pixels <= 32 ? 16 : 14)
    c.setLineCap(.round); c.setLineJoin(.round)
    c.move(to: CGPoint(x:378,y:115)); c.addLine(to: CGPoint(x:378,y:95))
    c.addCurve(to: CGPoint(x:348,y:65), control1: CGPoint(x:378,y:78.43), control2: CGPoint(x:364.57,y:65))
    c.addLine(to: CGPoint(x:232,y:65))
    c.addCurve(to: CGPoint(x:202,y:95), control1: CGPoint(x:215.43,y:65), control2: CGPoint(x:202,y:78.43))
    c.addLine(to: CGPoint(x:202,y:235))
    c.addCurve(to: CGPoint(x:232,y:265), control1: CGPoint(x:202,y:251.57), control2: CGPoint(x:215.43,y:265))
    c.addLine(to: CGPoint(x:348,y:265)); c.strokePath()
    c.move(to: CGPoint(x:224,y:224))
    for p in [CGPoint(x:271,y:158),CGPoint(x:310,y:207),CGPoint(x:335,y:176),CGPoint(x:371,y:224)] { c.addLine(to:p) }
    c.strokePath()
    for (a,b) in [(CGPoint(x:386,y:126),CGPoint(x:386,y:265)),(CGPoint(x:368,y:126),CGPoint(x:404,y:126)),(CGPoint(x:368,y:265),CGPoint(x:404,y:265))] {
        c.move(to:a); c.addLine(to:b)
    }
    c.strokePath()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
for dark in [false, true] {
let name = dark ? "AppIconDark" : "AppIcon"
let iconset = root.appendingPathComponent(".build/\(name).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16,32,128,256,512] {
    for scale in [1,2] {
        let suffix = scale == 2 ? "@2x" : ""
        try render(size*scale, dark: dark).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
try render(1024, dark: dark).write(to: root.appendingPathComponent("assets/\(name).png"))
let tool = Process(); tool.executableURL = URL(fileURLWithPath:"/usr/bin/iconutil")
tool.arguments = ["-c","icns",iconset.path,"-o",root.appendingPathComponent("assets/\(name).icns").path]
try tool.run(); tool.waitUntilExit()
guard tool.terminationStatus == 0 else { fatalError("iconutil failed") }

}
