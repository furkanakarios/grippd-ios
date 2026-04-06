import Foundation

struct Review: Identifiable, Codable {
    let id: UUID
    let userID: UUID
    let contentID: UUID
    var body: String
    var likeCount: Int
    let createdAt: Date
    var updatedAt: Date
}
