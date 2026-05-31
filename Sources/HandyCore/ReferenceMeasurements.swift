import CoreGraphics

public struct ReferenceRect: Equatable, Sendable {
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum ReferenceMeasurements1280x800 {
    public static let viewport = CGSize(width: 1280, height: 800)
    public static let panel = ReferenceRect(x: 92, y: 18, width: 760, height: 764)
    public static let shell = ReferenceRect(x: 92, y: 18, width: 760, height: 775)
    public static let header = ReferenceRect(x: 121, y: 47, width: 702, height: 89)
    public static let search = ReferenceRect(x: 121, y: 152, width: 702, height: 54)
    public static let pills = ReferenceRect(x: 121, y: 222, width: 702, height: 34)
    public static let goal = ReferenceRect(x: 121, y: 272, width: 702, height: 67)
    public static let gallery = ReferenceRect(x: 121, y: 355, width: 702, height: 330)
    public static let firstCard = ReferenceRect(x: 121, y: 357, width: 270, height: 318)
    public static let footer = ReferenceRect(x: 121, y: 701, width: 702, height: 63)
    public static let peek = ReferenceRect(x: 121, y: 173, width: 702, height: 264)
    public static let draft = ReferenceRect(x: 121, y: 584, width: 702, height: 104)
    public static let defaultSelectedIDs: Set<String> = ["ctx-code-position", "ctx-image-surface"]
}
