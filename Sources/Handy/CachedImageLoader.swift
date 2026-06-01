import AppKit

@MainActor
enum CachedImageLoader {
    private static let cache = NSCache<NSString, NSImage>()

    static func image(contentsOfFile path: String) -> NSImage? {
        let key = path as NSString
        if let image = cache.object(forKey: key) {
            return image
        }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
