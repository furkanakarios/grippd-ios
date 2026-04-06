import Foundation

final class SearchHistoryService {
    static let shared = SearchHistoryService()

    private let key = "grippd.searchHistory"
    private let maxItems = 10

    private init() {}

    var history: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var current = history.filter { $0.lowercased() != trimmed.lowercased() }
        current.insert(trimmed, at: 0)
        if current.count > maxItems { current = Array(current.prefix(maxItems)) }
        UserDefaults.standard.set(current, forKey: key)
    }

    func remove(_ query: String) {
        let updated = history.filter { $0 != query }
        UserDefaults.standard.set(updated, forKey: key)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
