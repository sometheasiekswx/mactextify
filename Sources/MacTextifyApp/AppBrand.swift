import AppKit

/// Finder uses the default bundle icon. The running app follows its appearance.
@MainActor enum AppBrand {
    static func icon(dark: Bool, bundle: Bundle = .main) -> NSImage? {
        guard let url = bundle.url(forResource: dark ? "AppIconDark" : "AppIcon", withExtension: "icns") else { return nil }
        return NSImage(contentsOf: url)
    }
    static func apply(dark: Bool) {
        guard let image = icon(dark: dark) else { return }
        NSApplication.shared.applicationIconImage = image
    }
}
