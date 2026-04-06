import Foundation
import SwiftData

@MainActor
final class UserContentService {
    static let shared = UserContentService()

    private var context: ModelContext { LocalCacheService.shared.context }

    private init() {}

    // MARK: - Fetch

    func all() -> [UserCreatedContent] {
        let descriptor = FetchDescriptor<UserCreatedContent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func find(id: String) -> UserCreatedContent? {
        let descriptor = FetchDescriptor<UserCreatedContent>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? context.fetch(descriptor))?.first
    }

    func search(query: String) -> [UserCreatedContent] {
        let lower = query.lowercased()
        return all().filter { $0.title.lowercased().contains(lower) }
    }

    // MARK: - Save / Delete

    func save(_ item: UserCreatedContent) {
        context.insert(item)
        try? context.save()
    }

    func update(_ item: UserCreatedContent) {
        try? context.save()
    }

    func delete(_ item: UserCreatedContent) {
        context.delete(item)
        try? context.save()
    }
}
