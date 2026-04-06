import Foundation

protocol BooksRepositoryProtocol {
    func search(query: String, page: Int) async throws -> [Content]
    func fetchDetail(googleBooksID: String) async throws -> Content
}

// MARK: - Google Books implementasyonu (Open Library fallback ile)

final class GoogleBooksRepository: BooksRepositoryProtocol {
    private let google = GoogleBooksClient.shared
    private let openLibrary = OpenLibraryClient.shared

    func search(query: String, page: Int = 1) async throws -> [Content] {
        do {
            let response = try await google.search(query: query, startIndex: (page - 1) * 20)
            let results = (response.items ?? []).map { BooksMapper.toContent($0) }
            if !results.isEmpty { return results }
        } catch {}

        // Fallback: Open Library
        let response = try await openLibrary.search(query: query, page: page)
        return response.docs.map { BooksMapper.toContent($0) }
    }

    func fetchDetail(googleBooksID: String) async throws -> Content {
        let book = try await google.volumeDetail(id: googleBooksID)
        return BooksMapper.toContent(book)
    }
}
