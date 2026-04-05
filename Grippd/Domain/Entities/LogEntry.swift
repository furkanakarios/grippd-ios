import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let userID: UUID
    let contentID: UUID
    var watchedAt: Date
    var rating: Double?        // 0.0 – 10.0, 0.5 adımlarla
    var emojiReaction: String?
    var isRewatch: Bool
    var notes: String?
    let createdAt: Date
}
