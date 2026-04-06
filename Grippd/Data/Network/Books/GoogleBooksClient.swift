import Foundation

final class GoogleBooksClient {
    static let shared = GoogleBooksClient()

    private let baseURL = "https://www.googleapis.com/books/v1"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search

    func search(query: String, startIndex: Int = 0, maxResults: Int = 20) async throws -> GoogleBooksResponse {
        try await get("volumes", params: [
            "q": query,
            "startIndex": "\(startIndex)",
            "maxResults": "\(maxResults)",
            "printType": "books",
            "projection": "lite"
        ])
    }

    func searchByISBN(_ isbn: String) async throws -> GoogleBooksResponse {
        try await get("volumes", params: ["q": "isbn:\(isbn)"])
    }

    // MARK: - Detail

    func volumeDetail(id: String) async throws -> GoogleBook {
        try await get("volumes/\(id)")
    }

    // MARK: - Generic Request

    private func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else { throw BooksError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw BooksError.httpError
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Errors

enum BooksError: LocalizedError {
    case invalidURL
    case httpError
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL."
        case .httpError: return "Sunucu hatası."
        case .notFound: return "Kitap bulunamadı."
        }
    }
}
