import AppKit
import HandyCore

@MainActor
final class ClipboardCaptureService {
    var onItemsChanged: (([ContextItem]) -> Void)?

    private let repository: any ContextRepository
    private let linkPreviewService: LinkPreviewService
    private let pasteboard: NSPasteboard
    private var timer: Timer?
    private var lastChangeCount: Int

    init(repository: any ContextRepository, pasteboard: NSPasteboard = .general) {
        self.repository = repository
        self.linkPreviewService = LinkPreviewService(repository: repository)
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        stop()
        lastChangeCount = pasteboard.changeCount
        let timer = Timer(timeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let item = captureCurrentPasteboardItem() else { return }

        do {
            let items = try repository.prepend(item)
            onItemsChanged?(items)
            linkPreviewService.enrich(item) { [weak self] items in
                self?.onItemsChanged?(items)
            }
        } catch {
            assertionFailure("Failed to persist clipboard context: \(error)")
        }
    }

    private func captureCurrentPasteboardItem() -> ContextItem? {
        let source = currentSource()
        guard source.name != "Handy" else { return nil }

        if let item = captureFileURL(source: source) {
            return item
        }
        if let item = captureImage(source: source) {
            return item
        }
        if let string = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty {
            return captureString(string, source: source)
        }
        return nil
    }

    private func captureFileURL(source: CaptureSource) -> ContextItem? {
        let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL]
        guard let url = urls?.first, url.isFileURL else { return nil }

        if let imageItem = Self.imageFileItem(for: url, source: source, repository: repository) {
            return imageItem
        }

        return ContextItem(
            id: makeID(),
            type: .file,
            title: url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent,
            preview: url.path,
            source: source.name == "Clipboard" ? "Finder" : source.name,
            age: "now",
            accent: "#a6b889",
            detail: url.pathExtension.isEmpty ? "File" : url.pathExtension.uppercased(),
            capturedAt: Date(),
            sourceBundleIdentifier: source.bundleIdentifier,
            sourceIconPath: source.iconPath
        )
    }

    private func captureImage(source: CaptureSource) -> ContextItem? {
        guard let image = NSImage(pasteboard: pasteboard) else { return nil }
        let id = makeID()
        let thumbnailPath = persistThumbnail(image, id: id)
        return ContextItem(
            id: id,
            type: .image,
            title: "Clipboard image",
            preview: "Image copied from \(source.name)",
            source: source.name,
            age: "now",
            accent: "#c99595",
            detail: image.pixelSizeLabel,
            thumbnailPath: thumbnailPath,
            capturedAt: Date(),
            sourceBundleIdentifier: source.bundleIdentifier,
            sourceIconPath: source.iconPath
        )
    }

    private func captureString(_ string: String, source: CaptureSource) -> ContextItem {
        if let url = URL(string: string), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
            return ContextItem(
                id: makeID(),
                type: .url,
                title: url.host(percentEncoded: false) ?? "Copied link",
                preview: string,
                source: source.name == "Clipboard" ? "Browser" : source.name,
                age: "now",
                accent: "#87a9d9",
                detail: url.host(percentEncoded: false) ?? string,
                capturedAt: Date(),
                sourceBundleIdentifier: source.bundleIdentifier,
                sourceIconPath: source.iconPath
            )
        }

        let type: ContextType = looksLikeCode(string) ? .code : .text
        return ContextItem(
            id: makeID(),
            type: type,
            title: firstLineTitle(from: string),
            preview: string.truncated(to: 180),
            source: source.name,
            age: "now",
            accent: type == .code ? "#d6b879" : "#8bc7b2",
            detail: type == .code ? "Copied code" : "Copied text",
            capturedAt: Date(),
            sourceBundleIdentifier: source.bundleIdentifier,
            sourceIconPath: source.iconPath
        )
    }

    private func persistThumbnail(_ image: NSImage, id: String) -> String? {
        ContextAssetWriter.persistThumbnail(image, id: id, repository: repository)
    }

    static func normalizedStoredImageFile(_ item: ContextItem, repository: any ContextRepository) -> ContextItem? {
        guard item.type == .file else { return nil }
        let url = URL(fileURLWithPath: item.preview)
        guard isSupportedImageFile(url), let image = NSImage(contentsOf: url) else { return nil }
        let thumbnailPath = ContextAssetWriter.persistThumbnail(image, id: item.id, repository: repository)
        return ContextItem(
            id: item.id,
            type: .image,
            title: item.title,
            preview: item.preview,
            source: item.source,
            age: item.age,
            accent: "#c99595",
            detail: image.pixelSizeLabel,
            thumbnailPath: thumbnailPath,
            capturedAt: item.capturedAt,
            sourceBundleIdentifier: item.sourceBundleIdentifier,
            sourceIconPath: item.sourceIconPath
        )
    }

    static func imageFileItem(for url: URL, source: CaptureSource, repository: any ContextRepository) -> ContextItem? {
        guard isSupportedImageFile(url), let image = NSImage(contentsOf: url) else { return nil }
        let id = makeID()
        let thumbnailPath = ContextAssetWriter.persistThumbnail(image, id: id, repository: repository)
        return ContextItem(
            id: id,
            type: .image,
            title: url.lastPathComponent.isEmpty ? "Copied image" : url.lastPathComponent,
            preview: url.path,
            source: source.name == "Clipboard" ? "Finder" : source.name,
            age: "now",
            accent: "#c99595",
            detail: image.pixelSizeLabel,
            thumbnailPath: thumbnailPath,
            capturedAt: Date(),
            sourceBundleIdentifier: source.bundleIdentifier,
            sourceIconPath: source.iconPath
        )
    }

    private static func isSupportedImageFile(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg", "heic", "webp", "gif", "tif", "tiff", "bmp"].contains(url.pathExtension.lowercased())
    }

    private func currentSource() -> CaptureSource {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return CaptureSource(name: "Clipboard", bundleIdentifier: nil, iconPath: nil)
        }
        let iconPath = app.icon.flatMap { ContextAssetWriter.persistSourceIcon($0, app: app, repository: repository) }
        return CaptureSource(
            name: app.localizedName ?? "Clipboard",
            bundleIdentifier: app.bundleIdentifier,
            iconPath: iconPath
        )
    }

    private func makeID() -> String {
        Self.makeID()
    }

    private static func makeID() -> String {
        "ctx-clip-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(6))"
    }

    private func firstLineTitle(from string: String) -> String {
        string
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .truncated(to: 56) ?? "Copied text"
    }

    private func looksLikeCode(_ string: String) -> Bool {
        let markers = ["func ", "let ", "var ", "class ", "struct ", "import ", "=>", "const ", "return ", "{", "}", ";"]
        let hits = markers.filter { string.contains($0) }.count
        return hits >= 2 || string.contains("\n    ") || string.contains("\n\t")
    }
}

struct CaptureSource {
    let name: String
    let bundleIdentifier: String?
    let iconPath: String?
}

private extension String {
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        let end = index(startIndex, offsetBy: maxLength)
        return String(self[..<end]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

private extension NSImage {
    var pixelSizeLabel: String {
        guard let representation = representations.first else { return "Image" }
        return "\(representation.pixelsWide) x \(representation.pixelsHigh)"
    }
}
