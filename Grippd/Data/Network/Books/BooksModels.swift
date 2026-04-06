import Foundation

// MARK: - Google Books

struct GoogleBook: Decodable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo
    let selfLink: String?

    struct VolumeInfo: Decodable {
        let title: String
        let authors: [String]?
        let description: String?
        let publishedDate: String?
        let pageCount: Int?
        let categories: [String]?
        let averageRating: Double?
        let ratingsCount: Int?
        let imageLinks: ImageLinks?
        let language: String?
        let industryIdentifiers: [Identifier]?

        struct ImageLinks: Decodable {
            let thumbnail: String?
            let smallThumbnail: String?

            var thumbnailURL: URL? {
                guard let raw = thumbnail ?? smallThumbnail else { return nil }
                // Google Books HTTP → HTTPS
                return URL(string: raw.replacingOccurrences(of: "http://", with: "https://"))
            }
        }

        struct Identifier: Decodable {
            let type: String
            let identifier: String
        }

        var isbn: String? {
            industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
                ?? industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
        }

        var publishYear: String? {
            publishedDate.flatMap { $0.split(separator: "-").first.map(String.init) }
        }
    }
}

struct GoogleBooksResponse: Decodable {
    let totalItems: Int
    let items: [GoogleBook]?
}

// MARK: - Open Library (backup)

struct OpenLibraryWork: Decodable, Identifiable {
    let key: String
    let title: String
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let subject: [String]?
    let ratingsAverage: Double?
    let ratingsCount: Int?
    let numberOfPagesMedian: Int?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, title, subject
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverI = "cover_i"
        case ratingsAverage = "ratings_average"
        case ratingsCount = "ratings_count"
        case numberOfPagesMedian = "number_of_pages_median"
    }

    var coverURL: URL? {
        guard let id = coverI else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(id)-L.jpg")
    }
}

struct OpenLibrarySearchResponse: Decodable {
    let numFound: Int
    let docs: [OpenLibraryWork]
}
