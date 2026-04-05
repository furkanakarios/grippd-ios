import Foundation

struct Content: Identifiable, Codable, Equatable {
    let id: UUID
    var tmdbID: Int?
    var googleBooksID: String?
    var type: ContentType
    var title: String
    var overview: String?
    var posterURL: URL?
    var backdropURL: URL?
    var releaseDate: Date?
    var genres: [String]
    var isUserCreated: Bool
    var createdByUserID: UUID?

    enum ContentType: String, Codable {
        case movie
        case tvShow = "tv_show"
        case book
    }
}
