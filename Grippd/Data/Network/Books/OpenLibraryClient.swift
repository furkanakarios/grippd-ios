import Foundation

final class OpenLibraryClient {
    static let shared = OpenLibraryClient()

    private let baseURL = "https://openlibrary.org"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search

    func search(query: String, page: Int = 1, limit: Int = 20) async throws -> OpenLibrarySearchResponse {
        try await get("search.json", params: [
            "q": query,
            "page": "\(page)",
            "limit": "\(limit)",
            "fields": "key,title,author_name,first_publish_year,cover_i,subject,ratings_average,ratings_count,number_of_pages_median"
        ])
    }

    // MARK: - Generic Request

    private func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else { throw BooksError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw BooksError.httpError(statusCode: 0)
        }
        guard (200...299).contains(http.statusCode) else {
            throw BooksError.httpError(statusCode: http.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
