import Foundation

protocol ContentRepositoryProtocol {
    func search(query: String, type: Content.ContentType?) async throws -> [Content]
    func fetchTrending(type: Content.ContentType, page: Int) async throws -> [Content]
    func fetchMovieDetail(tmdbID: Int) async throws -> Content
    func fetchTVDetail(tmdbID: Int) async throws -> Content
    func fetchSeasonDetail(showTmdbID: Int, seasonNumber: Int) async throws -> TMDBSeason
    func addUserContent(_ content: Content) async throws -> Content
}
