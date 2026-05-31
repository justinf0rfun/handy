import Foundation

public enum ContextType: String, CaseIterable, Identifiable, Sendable {
    case text
    case code
    case url
    case image
    case file
    case thought

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .text: "Text"
        case .code: "Code"
        case .url: "Links"
        case .image: "Visuals"
        case .file: "Files"
        case .thought: "Thoughts"
        }
    }
}

public enum ContextFilter: Hashable, Identifiable, Sendable {
    case all
    case type(ContextType)

    public var id: String {
        switch self {
        case .all: "all"
        case .type(let type): type.rawValue
        }
    }

    public var label: String {
        switch self {
        case .all: "All"
        case .type(let type): type.label
        }
    }

    public static let allCases: [ContextFilter] = [
        .all,
        .type(.code),
        .type(.image),
        .type(.url),
        .type(.file),
        .type(.thought),
        .type(.text)
    ]
}

public struct ContextItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let type: ContextType
    public let title: String
    public let preview: String
    public let source: String
    public let age: String
    public let accent: String
    public let detail: String
    public let thumbnailPath: String?
    public let capturedAt: Date?
    public let sourceBundleIdentifier: String?
    public let sourceIconPath: String?

    public init(
        id: String,
        type: ContextType,
        title: String,
        preview: String,
        source: String,
        age: String,
        accent: String,
        detail: String,
        thumbnailPath: String? = nil,
        capturedAt: Date? = nil,
        sourceBundleIdentifier: String? = nil,
        sourceIconPath: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.preview = preview
        self.source = source
        self.age = age
        self.accent = accent
        self.detail = detail
        self.thumbnailPath = thumbnailPath
        self.capturedAt = capturedAt
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.sourceIconPath = sourceIconPath
    }

    public func matches(_ term: String) -> Bool {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let haystack = "\(title) \(preview) \(source) \(detail)".lowercased()
        return haystack.contains(trimmed.lowercased())
    }

    public func displayAge(now: Date = Date()) -> String {
        guard let capturedAt else { return age }
        let elapsed = max(0, Int(now.timeIntervalSince(capturedAt)))
        if elapsed < 60 { return "now" }
        let minutes = elapsed / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}

public enum HandyFixtures {
    public static let intents = [
        "Debug this",
        "Implement this",
        "Review this",
        "Explain this",
        "Turn into task",
        "Create goal"
    ]

    public static let defaultGoal = "Implement the edge-aware summon panel without bringing back the old floating hand."
    public static let defaultIntent = "Implement this"
    public static let defaultSelectedIDs: Set<String> = ["ctx-code-position", "ctx-image-surface"]
    public static let defaultActiveID = "ctx-code-position"

    public static let contextItems: [ContextItem] = [
        ContextItem(
            id: "ctx-clip-error",
            type: .text,
            title: "Renderer crash note",
            preview: "Panel flickers when the gallery repaints after selection. Looks tied to root size mutation.",
            source: "Clipboard",
            age: "2m",
            accent: "#8bc7b2",
            detail: "Captured from issue triage"
        ),
        ContextItem(
            id: "ctx-code-position",
            type: .code,
            title: "Positioning branch",
            preview: "if (origin.x + width > frame.maxX) { origin.x = anchor.x - width - gap }",
            source: "Editor",
            age: "6m",
            accent: "#d6b879",
            detail: "Swift sketch"
        ),
        ContextItem(
            id: "ctx-url-gsap",
            type: .url,
            title: "GSAP timeline docs",
            preview: "Timeline defaults, labels, and position parameter notes for staged panel motion.",
            source: "Browser",
            age: "11m",
            accent: "#87a9d9",
            detail: "gsap.com"
        ),
        ContextItem(
            id: "ctx-image-surface",
            type: .image,
            title: "Dark surface reference",
            preview: "A cropped command surface with search, category pills, and media-heavy context cards.",
            source: "Screenshot",
            age: "18m",
            accent: "#c99595",
            detail: "1280 x 800",
            thumbnailPath: "/Users/justin/workspace/handy/prototype/reference-pack/2026-05-31/prototype-1280x800.png"
        ),
        ContextItem(
            id: "ctx-file-prd",
            type: .file,
            title: "Handy PRD",
            preview: "/Users/justin/workspace/handy/docs/prd.md",
            source: "Finder",
            age: "24m",
            accent: "#a6b889",
            detail: "Markdown"
        ),
        ContextItem(
            id: "ctx-thought-slogan",
            type: .thought,
            title: "Attention promise",
            preview: "Handy should feel summoned into the current task, not launched as another destination.",
            source: "Quick thought",
            age: "31m",
            accent: "#b8a2d1",
            detail: "Product note"
        )
    ]
}
