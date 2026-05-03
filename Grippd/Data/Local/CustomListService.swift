import Foundation
import SwiftData

@MainActor
final class CustomListService {
    static let shared = CustomListService()

    private var context: ModelContext { LocalCacheService.shared.context }

    private init() {}

    // MARK: - Lists

    func allLists() -> [CustomList] {
        let descriptor = FetchDescriptor<CustomList>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func createList(name: String, emoji: String) -> CustomList {
        let list = CustomList(name: name, emoji: emoji)
        context.insert(list)
        try? context.save()
        Task { await ListSyncService.shared.syncList(list) }
        return list
    }

    func updateList(_ list: CustomList, name: String, emoji: String) {
        list.name = name
        list.emoji = emoji
        list.updatedAt = Date()
        try? context.save()
        Task { await ListSyncService.shared.syncList(list) }
    }

    func deleteList(_ list: CustomList) {
        let listID = list.id
        context.delete(list)
        try? context.save()
        Task { await ListSyncService.shared.deleteList(listID: listID) }
    }

    // MARK: - Items

    func addItem(to list: CustomList, contentKey: String, contentType: Content.ContentType, title: String, posterPath: String?) {
        // Zaten listede varsa ekleme
        guard !isInList(list, contentKey: contentKey) else { return }
        let item = CustomListItem(contentKey: contentKey, contentType: contentType, contentTitle: title, posterPath: posterPath)
        item.list = list
        context.insert(item)
        list.updatedAt = Date()
        try? context.save()
        Task { await ListSyncService.shared.syncItem(listID: list.id, item: item) }
    }

    func removeItem(from list: CustomList, contentKey: String) {
        let listID = list.id
        let items = list.items.filter { $0.contentKey == contentKey }
        items.forEach { context.delete($0) }
        list.updatedAt = Date()
        try? context.save()
        Task { await ListSyncService.shared.removeItem(listID: listID, contentKey: contentKey) }
    }

    func isInList(_ list: CustomList, contentKey: String) -> Bool {
        list.items.contains { $0.contentKey == contentKey }
    }

    func listsContaining(contentKey: String) -> [CustomList] {
        allLists().filter { isInList($0, contentKey: contentKey) }
    }
}
