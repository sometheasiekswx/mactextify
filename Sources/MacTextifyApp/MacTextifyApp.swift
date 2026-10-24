import SwiftUI
import AppKit
import UniformTypeIdentifiers
import OCRCore

struct QueueItem: Identifiable {
    let url: URL
    var id: String { url.path }
    var state = "Ready"
    var detail = ""
    var output: URL?
}
@MainActor final class Session: ObservableObject {
    @Published var items: [QueueItem] = []
    @Published var exclusions: [String] = []
    @Published var parent: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    @Published var newFolder = true
    @Published var folder = "Extracted text"
    @Published var format = ExportFormat.text
    @Published var recursive = false
    @Published var engine = OCREngine.liveText
    @Published var busy = false
    @Published var scanning = false
    @Published var message = ""
    var job: Task<Void,Never>?
    var scanJob: Task<Void,Never>?
    var scopes: [URL] = []
    var destination: URL? { guard let parent else { return nil }; return try? BatchDestination.resolve(parent: parent, folderName: newFolder ? folder : nil) }
    var validation: String? {
        guard parent != nil else { return "Choose an output location." }
        guard destination != nil else { return "Enter a folder name without slashes or leading dots." }
        return nil
    }
    func access(_ url: URL) { if url.startAccessingSecurityScopedResource() { scopes.append(url) } }
    deinit { for url in scopes { url.stopAccessingSecurityScopedResource() } }
    func choose() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.png,.jpeg]
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = "Add"; panel.title = "Add files or folders"
        panel.begin { response in if response == .OK { self.add(panel.urls) } }
    }
    func chooseOutput() {
        let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = true
        panel.prompt = "Choose location"; panel.directoryURL = parent
        panel.begin { response in if response == .OK, let url = panel.url { self.access(url); self.parent = url } }
    }
    func add(_ urls: [URL]) {
        guard !busy, !scanning else { return }
        for url in urls { access(url) }
        scanning = true; message = "Checking selected files…"
        let recurse = recursive
        scanJob = Task {
            do {
                let worker = Task.detached { try BatchSelection.scan(urls, recursive: recurse) }
                let result = try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
                let existing = Set(items.map(\.url))
                items += result.files.filter { !existing.contains($0) }.map { QueueItem(url: $0) }
                exclusions += result.excluded
                message = "\(items.count) images ready. \(exclusions.count) excluded."
            } catch { message = "Selection stopped: \(error)" }
            scanning = false
        }
    }
    func run() {
        guard let destination, validation == nil, !items.isEmpty, !busy else { return }
        busy = true; message = "Extracting on your Mac…"
        for i in items.indices { items[i].state = "Ready"; items[i].detail = ""; items[i].output = nil }
        let urls = items.map(\.url)
        var config = Configuration(); config.format = format; config.engine = engine
        if engine == .vision { config.layout = .whole }
        job = Task {
            do {
                try await BatchProcessor().process(files: urls, destination: destination, configuration: config) { event in
                    await MainActor.run {
                        if let i = self.items.firstIndex(where: { $0.url == event.source }) {
                            self.items[i].state = event.state.rawValue.capitalized
                            self.items[i].detail = event.detail; self.items[i].output = event.output
                        }
                    }
                }
                message = Task.isCancelled ? "Stopped. Completed exports are preserved." : "Finished. \(items.filter { $0.output != nil }.count) of \(items.count) images available."
            } catch { message = "Cannot continue: \(error)" }
            busy = false
        }
    }
}

@main struct MacTextifyApplication: App {
    @StateObject private var session = Session()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        WindowGroup("MacTextify", id: "narrow-workspace") {
            PearlView(session: session).onAppear { delegate.session = session }
        }
        .defaultSize(width: 544, height: 720)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add files or folders…") { session.choose() }.keyboardShortcut("o").disabled(session.busy || session.scanning)
            }
        }
    }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var session: Session?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let session, session.busy || session.scanning else { return .terminateNow }
        let alert = NSAlert(); alert.messageText = "Stop extraction and quit?"; alert.informativeText = "Completed exports are preserved. In-flight work will finish its safe checkpoint."
        alert.addButton(withTitle: "Keep working"); alert.addButton(withTitle: "Stop and quit")
        guard alert.runModal() == .alertSecondButtonReturn else { return .terminateCancel }
        session.job?.cancel(); session.scanJob?.cancel()
        Task { await session.job?.value; await session.scanJob?.value; NSApp.reply(toApplicationShouldTerminate: true) }
        return .terminateLater
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// A single-line, selectable path. Updating unrelated UI state preserves selection.
struct SelectablePath: NSViewRepresentable {
    let path: String
    let label: String
    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.isEditable = false; field.isSelectable = true
        field.isBordered = false; field.drawsBackground = false
        field.font = .systemFont(ofSize: 12)
        field.textColor = .labelColor
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }
    func updateNSView(_ field: NSTextField, context: Context) {
        if field.stringValue != path { field.stringValue = path }
        field.isSelectable = context.environment.isEnabled
        field.setAccessibilityLabel(label)
        field.toolTip = path
    }
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 200, height: 20)
    }
}

struct PearlView: View {
    @ObservedObject var session: Session
    @State private var expanded = true
    @State private var targeted = false
    @State private var showExclusions = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var settingsFocused: Bool
    private var ink: Color { colorScheme == .dark ? .white : .black }
    private var paper: Color { colorScheme == .dark ? .black : .white }
    private var hairline: Color { ink.opacity(0.16) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VStack(spacing: 12) {
                dropArea
                HStack {
                    Toggle("Include subfolders", isOn: $session.recursive).toggleStyle(.checkbox).disabled(session.scanning)
                    Spacer()
                    if session.scanning {
                        ProgressView().controlSize(.small)
                        Button("Stop adding") { session.scanJob?.cancel() }
                    } else if !session.items.isEmpty {
                        Button("Clear") { session.items = []; session.exclusions = []; session.message = "" }
                    }
                }.font(.caption)
                    .disabled(session.busy)
                if !session.items.isEmpty { queue }
                else if !session.exclusions.isEmpty { exclusionsButton.frame(maxWidth: .infinity, alignment: .trailing) }
                settings.fixedSize(horizontal: false, vertical: true).geometryGroup()
                if let issue = session.validation {
                    Label(issue, systemImage: "exclamationmark.triangle")
                        .font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.padding(16)
                // The queue/drop area, panel position and clipped body must
                // share a transaction, otherwise the panel jumps ahead of its body.
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.20), value: expanded)
            Divider()
            footer
        }
        .foregroundStyle(ink).tint(ink)
        .frame(minWidth: 544, minHeight: 680)
        .background(paper)
        .onChange(of: colorScheme, initial: true) { _, scheme in AppBrand.apply(dark: scheme == .dark) }
    }

    private var header: some View {
        HStack(spacing: 6) {
            if let icon = AppBrand.icon(dark: colorScheme == .dark) {
                Image(nsImage: icon).resizable().frame(width: 25, height: 25).accessibilityHidden(true)
            }
            Text("MacTextify").font(.system(size: 13, weight: .semibold))
            Spacer()
            Label("On-device", systemImage: "lock").font(.caption).foregroundStyle(.secondary)
        }.padding(.horizontal, 16).frame(height: 36)
    }

    private var dropArea: some View {
        Group {
            if session.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.viewfinder").font(.system(size: 36, weight: .light)).accessibilityHidden(true)
                    Text(targeted ? "Drop to add" : "Drop images or folders").font(.headline)
                    Text("PNG and JPEG").font(.caption).foregroundStyle(.secondary)
                    Button("Add files or folders…") { session.choose() }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "doc.viewfinder").font(.system(size: 20)).accessibilityHidden(true)
                    Text(targeted ? "Drop to add" : "Drop images or folders").font(.system(size: 12, weight: .medium))
                    Spacer(minLength: 4)
                    Button("Add files or folders…") { session.choose() }
                }
            }
        }.padding(16).frame(maxWidth: .infinity)
            .background(targeted ? ink.opacity(0.07) : paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(targeted ? ink : hairline, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .disabled(session.busy || session.scanning)
            .dropDestination(for: URL.self) { urls, _ in
                guard !session.busy, !session.scanning else { return false }
                session.add(urls); return true
            } isTargeted: { targeted = $0 }
    }

    private var exclusionsButton: some View {
        Button("\(session.exclusions.count) excluded") { showExclusions.toggle() }
            .font(.caption)
            .popover(isPresented: $showExclusions) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Excluded items").font(.headline)
                        ForEach(Array(session.exclusions.enumerated()), id: \.offset) { _, reason in
                            Text(reason).font(.caption).textSelection(.enabled)
                        }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                }.frame(width: 360, height: 220)
            }
    }

    private var queue: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(session.items.count) images").font(.caption.weight(.medium)).monospacedDigit()
                Spacer()
                if !session.exclusions.isEmpty { exclusionsButton }
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(session.items) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "doc").accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                                Text(item.detail.isEmpty ? item.url.deletingLastPathComponent().path : item.detail)
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }.help(item.detail.isEmpty ? item.url.path : item.detail)
                            Spacer(minLength: 4)
                            Text(item.state).font(.caption).lineLimit(1)
                            if let output = item.output {
                                Button { NSWorkspace.shared.open(output) } label: { Image(systemName: "doc.text.magnifyingglass") }
                                    .accessibilityLabel("Open export for \(item.url.lastPathComponent)")
                                Button { NSWorkspace.shared.activateFileViewerSelecting([output]) } label: { Image(systemName: "folder") }
                                    .accessibilityLabel("Reveal export for \(item.url.lastPathComponent)")
                            }
                            if !session.busy && !session.scanning {
                                Button { session.items.removeAll { $0.id == item.id } } label: { Image(systemName: "xmark").frame(width: 22, height: 24) }
                                    .buttonStyle(.plain).accessibilityLabel("Remove \(item.url.lastPathComponent)")
                            }
                        }.padding(.vertical, 8)
                        Divider()
                    }
                }
            }
        }.frame(minHeight: 64, maxHeight: .infinity)
    }

    private var settings: some View {
        VStack(spacing: 0) {
            Button {
                settingsFocused = true
                expanded.toggle()
            } label: {
                HStack {
                    Text("Extracted text settings").fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }.padding(12).contentShape(Rectangle())
            }.buttonStyle(.plain).focused($settingsFocused).accessibilityValue(expanded ? "Expanded" : "Collapsed")
            SettingsDisclosure(expanded: expanded) {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                    HStack(spacing: 8) {
                        Text("Location").frame(width: 76, alignment: .leading)
                        SelectablePath(path: session.parent?.path ?? "Not selected", label: "Output location")
                        Button("Choose…") { session.chooseOutput() }.disabled(session.busy)
                    }
                    Picker("Save into", selection: $session.newFolder) {
                        Text("New subfolder").tag(true); Text("Directly here").tag(false)
                    }.pickerStyle(.segmented).disabled(session.busy)
                    if session.newFolder {
                        HStack {
                            Text("Folder name").frame(width: 76, alignment: .leading)
                            TextField("Extracted text", text: $session.folder).textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Output folder name").disabled(session.busy)
                        }
                    }
                    HStack(spacing: 16) {
                        Picker("Format", selection: $session.format) {
                            Text("Text (.txt)").tag(ExportFormat.text); Text("Markdown (.md)").tag(ExportFormat.markdown)
                        }
                        Picker("Engine", selection: $session.engine) {
                            Text("Live Text").tag(OCREngine.liveText); Text("Vision OCR").tag(OCREngine.vision)
                        }
                    }.disabled(session.busy)
                }.font(.system(size: 12)).padding(.horizontal, 12).padding(.bottom, 10)

            }
            HStack(spacing: 8) {
                Text("Save to").font(.caption).foregroundStyle(.secondary)
                SelectablePath(path: session.destination?.path ?? "Choose a valid destination", label: "Resolved output path")
                Button {
                    guard let path = session.destination?.path else { return }
                    NSPasteboard.general.clearContents(); NSPasteboard.general.setString(path, forType: .string)
                } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.plain).help("Copy output path").accessibilityLabel("Copy output path")
                    .disabled(session.destination == nil)
            }.padding(.horizontal, 12).padding(.bottom, 12)
        }.overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(hairline))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Originals stay in place").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if session.busy {
                    ProgressView().controlSize(.small)
                    Button("Stop after current image") { session.job?.cancel(); session.message = "Stopping safely…" }
                } else {
                    Button("Extract text") { session.run() }
                        .buttonStyle(MonochromePrimaryStyle())
                        .disabled(session.items.isEmpty || session.scanning || session.validation != nil)
                        .keyboardShortcut(.return, modifiers: .command)
                }
            }
            if !session.message.isEmpty {
                Text(session.message).font(.caption).lineLimit(2).help(session.message)
                    .textSelection(.enabled).accessibilityLabel("Batch status: \(session.message)")
            }
        }.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

private struct DisclosureHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Stable controls reveal inside a clipped frame, without a competing slide transition.
private struct SettingsDisclosure<Content: View>: View {
    let expanded: Bool
    @ViewBuilder let content: Content
    @State private var height: CGFloat = 0
    var body: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { proxy in Color.clear.preference(key: DisclosureHeight.self, value: proxy.size.height) })
            .frame(height: expanded ? (height > 0 ? height : nil) : 0, alignment: .top)
            .clipped()
            .allowsHitTesting(expanded)
            .disabled(!expanded)
            .accessibilityElement(children: .contain)
            .accessibilityHidden(!expanded)
            .onPreferenceChange(DisclosureHeight.self) { height = $0 }
    }
}

private struct MonochromePrimaryStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label.font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 18).padding(.vertical, 9)
            .foregroundStyle(scheme == .dark ? Color.black : .white)
            .background(scheme == .dark ? Color.white : .black, in: RoundedRectangle(cornerRadius: 7))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.3)
    }
}
