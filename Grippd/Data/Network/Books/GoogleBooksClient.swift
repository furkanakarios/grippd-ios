import Foundation

final class GoogleBooksClient {
    static let shared = GoogleBooksClient()

    private let baseURL = "https://www.googleapis.com/books/v1"
    private let apiKey: String?
    private let session: URLSession

    private init() {
        apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksApiKey") as? String
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
            "printType": "books"
        ])
    }

    func searchFeatured(maxResults: Int = 15) async throws -> GoogleBooksResponse {
        try await get("volumes", params: [
            "q": "subject:fiction",
            "orderBy": "relevance",
            "maxResults": "\(maxResults)",
            "printType": "books",
            "langRestrict": "en"
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
        var allParams = params
        if let key = apiKey, !key.isEmpty {
            allParams["key"] = key
        }
        components.queryItems = allParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else { throw BooksError.invalidURL }

        var request = URLRequest(url: url)
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BooksError.httpError(statusCode: 0)
        }
        guard (200...299).contains(http.statusCode) else {
            throw BooksError.httpError(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw BooksError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - Errors

enum BooksError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case notFound
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL."
        case .httpError(let code): return "Sunucu hatası (\(code))."
        case .notFound: return "Kitap bulunamadı."
        case .decodingError(let msg): return "Veri hatası: \(msg)"
        }
    }
}
