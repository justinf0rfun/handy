import AppKit
import HandyCore
@preconcurrency import LinkPresentation
import UniformTypeIdentifiers

@MainActor
final class LinkPreviewService {
    private let repository: any ContextRepository
    private var inFlightIDs: Set<String> = []

    init(repository: any ContextRepository) {
        self.repository = repository
    }

    func enrich(_ item: ContextItem, onItemsChanged: @escaping @MainActor ([ContextItem]) -> Void) {
        guard item.type == .url,
              item.thumbnailPath == nil,
              inFlightIDs.insert(item.id).inserted,
              let url = URL(string: item.preview)
        else { return }

        Task { [weak self] in
            await self?.enrich(item, url: url, onItemsChanged: onItemsChanged)
        }
    }

    private func enrich(_ item: ContextItem, url: URL, onItemsChanged: @escaping @MainActor ([ContextItem]) -> Void) async {
        defer { inFlightIDs.remove(item.id) }

        do {
            let metadata = try await fetchMetadata(for: url).value
            var image = await loadPreviewImage(from: metadata)
            if image == nil {
                image = try? await fetchOpenGraphImage(for: url)
            }
            let thumbnailPath = image.flatMap { ContextAssetWriter.persistThumbnail($0, id: item.id, repository: repository) }
            let title = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = metadata.url?.host(percentEncoded: false) ?? metadata.originalURL?.host(percentEncoded: false) ?? item.detail

            guard title?.isEmpty == false || thumbnailPath != nil || detail != item.detail else { return }

            let enriched = ContextItem(
                id: item.id,
                type: item.type,
                title: title?.isEmpty == false ? title! : item.title,
                preview: item.preview,
                source: item.source,
                age: item.age,
                accent: item.accent,
                detail: detail,
                thumbnailPath: thumbnailPath ?? item.thumbnailPath,
                capturedAt: item.capturedAt,
                sourceBundleIdentifier: item.sourceBundleIdentifier,
                sourceIconPath: item.sourceIconPath
            )
            let items = try repository.update(enriched)
            onItemsChanged(items)
        } catch {
            return
        }
    }

    private func fetchMetadata(for url: URL) async throws -> UncheckedLinkMetadata {
        let provider = LPMetadataProvider()
        provider.timeout = 8
        return try await withCheckedThrowingContinuation { continuation in
            provider.startFetchingMetadata(for: url) { metadata, error in
                if let metadata {
                    continuation.resume(returning: UncheckedLinkMetadata(metadata))
                } else {
                    continuation.resume(throwing: error ?? LinkPreviewError.missingMetadata)
                }
            }
        }
    }

    private func loadPreviewImage(from metadata: LPLinkMetadata) async -> NSImage? {
        if let image = await loadImage(from: metadata.imageProvider) {
            return image
        }
        return await loadImage(from: metadata.iconProvider)
    }

    private func loadImage(from provider: NSItemProvider?) async -> NSImage? {
        guard let provider else { return nil }
        if provider.canLoadObject(ofClass: NSImage.self) {
            let image = await withCheckedContinuation { continuation in
                _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                    continuation.resume(returning: object as? NSImage)
                }
            }
            if let image {
                return image
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let data = await withCheckedContinuation { continuation in
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    continuation.resume(returning: data)
                }
            }
            if let data, let image = NSImage(data: data) {
                return image
            }
        }

        return nil
    }

    private func fetchOpenGraphImage(for url: URL) async throws -> NSImage? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data.prefix(400_000), encoding: .utf8) ?? String(data: data.prefix(400_000), encoding: .isoLatin1),
              let imageURL = firstPreviewImageURL(in: html, baseURL: url)
        else { return nil }

        var imageRequest = URLRequest(url: imageURL)
        imageRequest.timeoutInterval = 8
        imageRequest.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (imageData, _) = try await URLSession.shared.data(for: imageRequest)
        return NSImage(data: imageData)
    }

    private func firstPreviewImageURL(in html: String, baseURL: URL) -> URL? {
        for key in ["og:image:secure_url", "og:image", "twitter:image", "twitter:image:src"] {
            if let content = metaContent(named: key, in: html),
               let url = URL(string: content, relativeTo: baseURL)?.absoluteURL {
                return url
            }
        }
        return nil
    }

    private func metaContent(named key: String, in html: String) -> String? {
        let escapedKey = NSRegularExpression.escapedPattern(for: key)
        let patterns = [
            "<meta[^>]+(?:property|name)=[\"']\(escapedKey)[\"'][^>]+content=[\"']([^\"']+)[\"'][^>]*>",
            "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+(?:property|name)=[\"']\(escapedKey)[\"'][^>]*>"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            guard let match = regex.firstMatch(in: html, range: range),
                  let contentRange = Range(match.range(at: 1), in: html)
            else { continue }
            return String(html[contentRange])
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}

private enum LinkPreviewError: Error {
    case missingMetadata
}

private struct UncheckedLinkMetadata: @unchecked Sendable {
    let value: LPLinkMetadata

    init(_ value: LPLinkMetadata) {
        self.value = value
    }
}
