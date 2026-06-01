import CoreData
import Foundation

public enum ContextRepositoryError: Error {
    case invalidContextType(String)
}

public protocol ContextRepository: AnyObject, Sendable {
    var assetDirectoryURL: URL { get }

    func loadItems() throws -> [ContextItem]
    func loadPage(offset: Int, limit: Int, filter: ContextFilter, search: String) throws -> ContextPage
    func countItems(filter: ContextFilter, search: String) throws -> Int

    @discardableResult
    func prepend(_ item: ContextItem) throws -> [ContextItem]

    @discardableResult
    func update(_ item: ContextItem) throws -> [ContextItem]

    @discardableResult
    func delete(id: String) throws -> [ContextItem]
}

public struct ContextPage: Sendable, Equatable {
    public let items: [ContextItem]
    public let hasMore: Bool

    public init(items: [ContextItem], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}

public final class CoreDataContextRepository: ContextRepository, @unchecked Sendable {
    public let assetDirectoryURL: URL
    public let retentionLimit: Int?

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public convenience init(retentionLimit: Int? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let root = support ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let directory = root.appendingPathComponent("Handy", isDirectory: true)
        self.init(storeDirectory: directory, retentionLimit: retentionLimit)
    }

    public init(storeDirectory: URL, retentionLimit: Int? = nil, inMemory: Bool = false) {
        self.assetDirectoryURL = storeDirectory
        self.retentionLimit = retentionLimit
        self.container = NSPersistentContainer(name: "HandyContextStore", managedObjectModel: Self.modelBox.model)

        let description: NSPersistentStoreDescription
        if inMemory {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        } else {
            let storeURL = storeDirectory.appendingPathComponent("Handy.sqlite")
            description = NSPersistentStoreDescription(url: storeURL)
            description.type = NSSQLiteStoreType
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description]

        if !inMemory {
            try? FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            fatalError("Failed to load Handy Core Data store: \(loadError)")
        }

        self.context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        context.automaticallyMergesChangesFromParent = true
    }

    public func loadItems() throws -> [ContextItem] {
        try context.performAndWait {
            try fetchActiveObjects().map(Self.makeItem(from:))
        }
    }

    public func loadPage(offset: Int, limit: Int, filter: ContextFilter = .all, search: String = "") throws -> ContextPage {
        try context.performAndWait {
            let request = activeObjectsRequest(filter: filter, search: search)
            request.fetchOffset = max(0, offset)
            request.fetchLimit = max(1, limit) + 1
            let objects = try context.fetch(request)
            let pageObjects = Array(objects.prefix(max(1, limit)))
            return ContextPage(
                items: try pageObjects.map(Self.makeItem(from:)),
                hasMore: objects.count > pageObjects.count
            )
        }
    }

    public func countItems(filter: ContextFilter = .all, search: String = "") throws -> Int {
        try context.performAndWait {
            let request = StoredContextItem.fetchRequest()
            request.predicate = predicate(filter: filter, search: search)
            return try context.count(for: request)
        }
    }

    @discardableResult
    public func prepend(_ item: ContextItem) throws -> [ContextItem] {
        try context.performAndWait {
            let contentKey = Self.contentKey(for: item)
            let duplicateRequest = StoredContextItem.fetchRequest()
            duplicateRequest.predicate = NSPredicate(format: "contentKey == %@", contentKey)
            for object in try context.fetch(duplicateRequest) {
                context.delete(object)
            }

            let object = StoredContextItem(context: context)
            apply(item, to: object, preserveCreatedAt: false)

            try enforceRetentionLimit()
            try saveIfNeeded()
            return try fetchActiveObjects(limit: 24).map(Self.makeItem(from:))
        }
    }

    @discardableResult
    public func update(_ item: ContextItem) throws -> [ContextItem] {
        try context.performAndWait {
            let request = StoredContextItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", item.id)
            guard let object = try context.fetch(request).first else {
                return try fetchActiveObjects(limit: 24).map(Self.makeItem(from:))
            }

            apply(item, to: object, preserveCreatedAt: true)
            try saveIfNeeded()
            return try fetchActiveObjects(limit: 24).map(Self.makeItem(from:))
        }
    }

    @discardableResult
    public func delete(id: String) throws -> [ContextItem] {
        try context.performAndWait {
            let request = StoredContextItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            for object in try context.fetch(request) {
                context.delete(object)
            }
            try saveIfNeeded()
            return try fetchActiveObjects(limit: 24).map(Self.makeItem(from:))
        }
    }

    private func apply(_ item: ContextItem, to object: StoredContextItem, preserveCreatedAt: Bool) {
        object.id = item.id
        object.type = item.type.rawValue
        object.title = item.title
        object.preview = item.preview
        object.source = item.source
        object.age = item.age
        object.accent = item.accent
        object.detail = item.detail
        object.thumbnailPath = item.thumbnailPath
        object.capturedAt = item.capturedAt
        object.sourceBundleIdentifier = item.sourceBundleIdentifier
        object.sourceIconPath = item.sourceIconPath
        object.contentKey = Self.contentKey(for: item)
        if !preserveCreatedAt {
            object.createdAt = item.capturedAt ?? Date()
        }
    }

    private func fetchActiveObjects(limit: Int? = nil) throws -> [StoredContextItem] {
        let request = activeObjectsRequest(filter: .all, search: "")
        if let retentionLimit {
            request.fetchLimit = retentionLimit
        }
        if let limit {
            request.fetchLimit = min(request.fetchLimit > 0 ? request.fetchLimit : limit, limit)
        }
        return try context.fetch(request)
    }

    private func activeObjectsRequest(filter: ContextFilter, search: String) -> NSFetchRequest<StoredContextItem> {
        let request = StoredContextItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        request.predicate = predicate(filter: filter, search: search)
        return request
    }

    private func predicate(filter: ContextFilter, search: String) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        if case .type(let type) = filter {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }

        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            predicates.append(
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "title CONTAINS[cd] %@", trimmed),
                    NSPredicate(format: "preview CONTAINS[cd] %@", trimmed),
                    NSPredicate(format: "source CONTAINS[cd] %@", trimmed),
                    NSPredicate(format: "detail CONTAINS[cd] %@", trimmed)
                ])
            )
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func enforceRetentionLimit() throws {
        guard let retentionLimit else { return }
        let request = StoredContextItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        let objects = try context.fetch(request)
        guard objects.count > retentionLimit else { return }
        for object in objects.dropFirst(retentionLimit) {
            context.delete(object)
        }
    }

    private func saveIfNeeded() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    private static func makeItem(from object: StoredContextItem) throws -> ContextItem {
        guard let type = ContextType(rawValue: object.type) else {
            throw ContextRepositoryError.invalidContextType(object.type)
        }
        return ContextItem(
            id: object.id,
            type: type,
            title: object.title,
            preview: object.preview,
            source: object.source,
            age: object.age,
            accent: object.accent,
            detail: object.detail,
            thumbnailPath: object.thumbnailPath,
            capturedAt: object.capturedAt,
            sourceBundleIdentifier: object.sourceBundleIdentifier,
            sourceIconPath: object.sourceIconPath
        )
    }

    private static func contentKey(for item: ContextItem) -> String {
        "\(item.type.rawValue)|\(item.title)|\(item.preview)|\(item.detail)"
    }

    private static let modelBox = ManagedObjectModelBox(model: makeModel())

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "StoredContextItem"
        entity.managedObjectClassName = NSStringFromClass(StoredContextItem.self)

        entity.properties = [
            stringAttribute("id"),
            stringAttribute("type"),
            stringAttribute("title"),
            stringAttribute("preview"),
            stringAttribute("source"),
            stringAttribute("age"),
            stringAttribute("accent"),
            stringAttribute("detail"),
            stringAttribute("contentKey"),
            stringAttribute("thumbnailPath", optional: true),
            stringAttribute("sourceBundleIdentifier", optional: true),
            stringAttribute("sourceIconPath", optional: true),
            dateAttribute("capturedAt", optional: true),
            dateAttribute("createdAt")
        ]

        model.entities = [entity]
        return model
    }

    private static func stringAttribute(_ name: String, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = optional
        return attribute
    }

    private static func dateAttribute(_ name: String, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .dateAttributeType
        attribute.isOptional = optional
        return attribute
    }
}

private struct ManagedObjectModelBox: @unchecked Sendable {
    let model: NSManagedObjectModel
}

@objc(StoredContextItem)
private final class StoredContextItem: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var type: String
    @NSManaged var title: String
    @NSManaged var preview: String
    @NSManaged var source: String
    @NSManaged var age: String
    @NSManaged var accent: String
    @NSManaged var detail: String
    @NSManaged var contentKey: String
    @NSManaged var thumbnailPath: String?
    @NSManaged var capturedAt: Date?
    @NSManaged var sourceBundleIdentifier: String?
    @NSManaged var sourceIconPath: String?
    @NSManaged var createdAt: Date

    @nonobjc class func fetchRequest() -> NSFetchRequest<StoredContextItem> {
        NSFetchRequest<StoredContextItem>(entityName: "StoredContextItem")
    }
}
