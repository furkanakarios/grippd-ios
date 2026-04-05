import Foundation

// MARK: - Dependency Injection Container
// Repository'ler Faz 1 Step 3'te Supabase implementasyonlarıyla doldurulacak

final class DIContainer {

    static let shared = DIContainer()
    private init() {}

    // MARK: - Repositories (lazy — implementasyonlar sonraki adımlarda eklenir)
    lazy var contentRepository: ContentRepositoryProtocol = ContentRepositoryStub()
    lazy var userRepository: UserRepositoryProtocol = UserRepositoryStub()
    lazy var logRepository: LogRepositoryProtocol = LogRepositoryStub()
}

// MARK: - Stubs (gerçek implementasyon gelene kadar)
private struct ContentRepositoryStub: ContentRepositoryProtocol {
    func search(query: String, type: Content.ContentType?) async throws -> [Content] { [] }
    func fetchDetail(id: UUID) async throws -> Content { fatalError("Not implemented") }
    func fetchTrending(type: Content.ContentType) async throws -> [Content] { [] }
    func addUserContent(_ content: Content) async throws -> Content { content }
}

private struct UserRepositoryStub: UserRepositoryProtocol {
    func fetchProfile(id: UUID) async throws -> User { fatalError("Not implemented") }
    func updateProfile(_ user: User) async throws -> User { user }
    func follow(userID: UUID) async throws {}
    func unfollow(userID: UUID) async throws {}
    func fetchFollowers(userID: UUID) async throws -> [User] { [] }
    func fetchFollowing(userID: UUID) async throws -> [User] { [] }
}

private struct LogRepositoryStub: LogRepositoryProtocol {
    func fetchLogs(userID: UUID, contentID: UUID?) async throws -> [LogEntry] { [] }
    func addLog(_ entry: LogEntry) async throws -> LogEntry { entry }
    func updateLog(_ entry: LogEntry) async throws -> LogEntry { entry }
    func deleteLog(id: UUID) async throws {}
}
