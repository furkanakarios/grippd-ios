import Foundation

struct Content: Identifiable, Codable, Equatable {
    let id: UUID
    var tmdbID: Int?
    var googleBooksID: String?
    var title: String
    var originalTitle: String?
    var overview: String?
    var posterURL: URL?
    var backdropURL: URL?
    var releaseYear: Int?
    var contentType: ContentType
    var genres: [String]
    var averageRating: Double?
    var tmdbPopularity: Double?
    var runtime: Int?
    var isUserCreated: Bool
    var createdByUserID: UUID?
    var createdAt: Date

    enum ContentType: String, Codable {
        case movie
        case tv_show
        case book
    }
}
