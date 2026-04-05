import Foundation

protocol UserRepositoryProtocol {
    func fetchProfile(id: UUID) async throws -> User
    func updateProfile(_ user: User) async throws -> User
    func follow(userID: UUID) async throws
    func unfollow(userID: UUID) async throws
    func fetchFollowers(userID: UUID) async throws -> [User]
    func fetchFollowing(userID: UUID) async throws -> [User]
}
