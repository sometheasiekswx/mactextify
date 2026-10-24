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
    func choose(folderOnly: Bool) {
        let panel = NSOpenPanel(); panel.canChooseDirectories = folderOnly; panel.canChooseFiles = !folderOnly
        panel.allowsMultipleSelection = true
        if !folderOnly { panel.allowedContentTypes = [.png,.jpeg] }
        panel.prompt = "Add"; panel.title = folderOnly ? "Add folders" : "Add images"
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
        WindowGroup("MacTextify") {
            PearlView(session: session).onAppear { delegate.session = session }
        }
        .defaultSize(width: 780, height: 880)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add images…") { session.choose(folderOnly: false) }.keyboardShortcut("o").disabled(session.busy || session.scanning)
                Button("Add folders…") { session.choose(folderOnly: true) }.keyboardShortcut("o", modifiers: [.command,.shift]).disabled(session.busy || session.scanning)
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

struct PearlView: View {
    @ObservedObject var session: Session
    @State private var expanded = true
    @State private var targeted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var settingsFocused: Bool
    private let accent = Color(red: 0.27, green: 0.42, blue: 0.77)
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Group {
                    if let icon = AppBrand.icon(dark: colorScheme == .dark) {
                        Image(nsImage: icon).resizable().frame(width: 32, height: 32).accessibilityHidden(true)
                    }
                }
                Text("MacTextify").fontWeight(.semibold)
                Spacer()
                Label("On-device OCR", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
            }.onChange(of: colorScheme, initial: true) { _, scheme in
                AppBrand.apply(dark: scheme == .dark)
            }.padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 18).background(.bar)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("A little less typing.").font(.system(size: 29, weight: .semibold, design: .rounded))
                        Text("Bring your images. Take the words with you.").foregroundStyle(.secondary)
                    }
                    VStack(spacing: 12) {
                        Image(systemName: "doc.viewfinder").font(.system(size: 32, weight: .light)).foregroundStyle(accent)
                        Text(targeted ? "Drop to add to your batch" : "Images in. Words out.").font(.title3.weight(.medium))
                        Text("Drop images or folders here").foregroundStyle(.secondary)
                        HStack {
                            Button("Add files…") { session.choose(folderOnly: false) }
                            Button("Add folders…") { session.choose(folderOnly: true) }
                        }.controlSize(.large)
                        Text("PNG and JPEG • Your originals stay put").font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity).padding(22)
                        .background(targeted ? accent.opacity(0.13) : Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(accent.opacity(targeted ? 0.8 : 0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5,4])))
                        .disabled(session.busy || session.scanning)
                        .dropDestination(for: URL.self) { urls, _ in
                            guard !session.busy, !session.scanning else { return false }; session.add(urls); return true
                        } isTargeted: { targeted = $0 }
                    HStack {
                        Toggle("Include subfolders when adding", isOn: $session.recursive).toggleStyle(.checkbox)
                        Spacer()
                        if !session.items.isEmpty { Button("Clear queue") { session.items = []; session.exclusions = []; session.message = "" } }
                    }.font(.caption).disabled(session.busy || session.scanning)
                    if session.scanning { HStack { ProgressView().controlSize(.small); Text("Checking files…"); Button("Stop adding") { session.scanJob?.cancel() } } }
                    if !session.items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(session.items.count) images in this batch").font(.headline)
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(session.items) { item in
                                        HStack(spacing: 12) {
                                            Image(systemName: "doc.richtext").foregroundStyle(accent).font(.title2)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                                                Text(item.detail.isEmpty ? item.url.deletingLastPathComponent().path : item.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                            }
                                            Spacer()
                                            Text(item.state).font(.caption).foregroundStyle(.secondary)
                                            if let output = item.output {
                                                Button { NSWorkspace.shared.open(output) } label: { Image(systemName: "doc.text.magnifyingglass") }.help("Open export").accessibilityLabel("Open export for \(item.url.lastPathComponent)")
                                                Button { NSWorkspace.shared.activateFileViewerSelecting([output]) } label: { Image(systemName: "folder") }.help("Reveal export in Finder").accessibilityLabel("Reveal export for \(item.url.lastPathComponent)")
                                            }
                                            if !session.busy { Button { session.items.removeAll { $0.id == item.id } } label: { Image(systemName: "xmark") }.buttonStyle(.plain).accessibilityLabel("Remove \(item.url.lastPathComponent)") }
                                        }.padding(.vertical, 12)
                                        Divider()
                                    }
                                }
                            }.frame(height: min(CGFloat(session.items.count) * 70, 210))
                        }
                    }
                    if !session.exclusions.isEmpty {
                        DisclosureGroup("\(session.exclusions.count) excluded items") {
                            ForEach(Array(session.exclusions.enumerated()), id: \.offset) { _, reason in Text(reason).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
                        }
                    }
                    VStack(spacing: 0) {
                        Button {
                            settingsFocused = true
                            withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 1)) { expanded.toggle() }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Extracted text settings").fontWeight(.semibold)
                                    Text((session.destination?.path ?? "Choose a valid destination") + " · " + (session.format == .text ? "Plain text" : "Markdown")).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                                Spacer()
                                Text(expanded ? "Hide settings" : "Change settings").font(.caption).foregroundStyle(accent)
                                Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption).foregroundStyle(accent)
                            }.padding(18).contentShape(Rectangle())
                        }.buttonStyle(.plain).focused($settingsFocused).accessibilityValue(expanded ? "Expanded" : "Collapsed")
                        if expanded {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                HStack { Text("Location").foregroundStyle(.secondary).frame(width: 90, alignment: .leading); Text(session.parent?.path ?? "Not selected").lineLimit(1).truncationMode(.middle); Spacer(); Button("Choose…") { session.chooseOutput() } }
                                Picker("Save into", selection: $session.newFolder) { Text("New subfolder").tag(true); Text("Directly here").tag(false) }.pickerStyle(.segmented)
                                if session.newFolder { HStack { Text("Folder name").foregroundStyle(.secondary).frame(width: 90, alignment: .leading); TextField("Extracted text", text: $session.folder).textFieldStyle(.roundedBorder).accessibilityLabel("Output folder name") } }
                                Picker("Format", selection: $session.format) { Text("Plain text (.txt)").tag(ExportFormat.text); Text("Markdown (.md)").tag(ExportFormat.markdown) }
                                Picker("OCR engine", selection: $session.engine) { Text("Apple Live Text").tag(OCREngine.liveText); Text("Vision OCR").tag(OCREngine.vision) }
                                Text("Save to " + (session.destination?.path ?? "a valid destination")).font(.caption).foregroundStyle(.secondary).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(12).background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                                Text("Only extracted text is saved here. Your originals stay in place.").font(.caption).foregroundStyle(.secondary)
                            }.padding(.horizontal,18).padding(.bottom,18).disabled(session.busy).transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }.background(.background, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.12)))
                    if let issue = session.validation { Label(issue, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.red) }
                }.padding(28)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) { Text("Processed on your Mac."); Text("No uploads. Originals preserved.") }.font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if session.busy { ProgressView().controlSize(.small); Button("Stop after current image") { session.job?.cancel(); session.message = "Stopping safely…" } }
                    else { Button("Extract text") { session.run() }.buttonStyle(.borderedProminent).tint(accent).controlSize(.large).disabled(session.items.isEmpty || session.scanning || session.validation != nil).keyboardShortcut(.return, modifiers: .command) }
                }
                if !session.message.isEmpty { Text(session.message).font(.caption).foregroundStyle(.secondary).textSelection(.enabled).accessibilityLabel("Batch status: \(session.message)") }
            }.padding(20).background(.bar)
        }.frame(minWidth: 620, minHeight: 640).background(Color(nsColor: .windowBackgroundColor))
    }
}
