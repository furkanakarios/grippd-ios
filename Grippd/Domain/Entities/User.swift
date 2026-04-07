import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String?
    var avatarURL: URL?
    var bannerURL: URL?
    var isPrivate: Bool
    var planType: PlanType
    var interests: [String]
    let createdAt: Date

    enum PlanType: String, Codable {
        case free
        case premium
    }
}
