import AppKit
import HandyCore

enum ContextAssetWriter {
    static func persistThumbnail(_ image: NSImage, id: String, repository: any ContextRepository) -> String? {
        persistPNG(image, directory: repository.assetDirectoryURL.appendingPathComponent("Thumbnails", isDirectory: true), fileName: "\(id).png")
    }

    static func persistSourceIcon(_ icon: NSImage, app: NSRunningApplication, repository: any ContextRepository) -> String? {
        guard let bundleIdentifier = app.bundleIdentifier else { return nil }
        return persistPNG(
            icon,
            directory: repository.assetDirectoryURL.appendingPathComponent("SourceIcons", isDirectory: true),
            fileName: "\(bundleIdentifier).png"
        )
    }

    private static func persistPNG(_ image: NSImage, directory: URL, fileName: String) -> String? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(fileName)
            try png.write(to: url, options: [.atomic])
            return url.path
        } catch {
            return nil
        }
    }
}
