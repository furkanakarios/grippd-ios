import Foundation

protocol ContentRepositoryProtocol {
    func search(query: String, type: Content.ContentType?) async throws -> [Content]
    func fetchDetail(id: UUID) async throws -> Content
    func fetchTrending(type: Content.ContentType) async throws -> [Content]
    func addUserContent(_ content: Content) async throws -> Content
}
