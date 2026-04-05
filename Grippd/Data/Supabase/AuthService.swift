import Foundation
import Supabase
import AuthenticationServices

final class AuthService {
    static let shared = AuthService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Sign in with Apple

    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return try await fetchOrCreateProfile(authUser: session.user)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Session Restore

    func restoreSession() async throws -> User? {
        do {
            let session = try await client.auth.session
            return try await fetchOrCreateProfile(authUser: session.user)
        } catch {
            return nil
        }
    }

    // MARK: - Profile Fetch / Create

    private func fetchOrCreateProfile(authUser: Supabase.User) async throws -> User {
        let id = authUser.id

        // Try to fetch existing profile
        let rows: [UserRow] = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        if let row = rows.first {
            return row.toDomain()
        }

        // Profile created by DB trigger (handle_new_user), wait briefly and retry
        try await Task.sleep(for: .milliseconds(500))
        let retried: [UserRow] = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        if let row = retried.first {
            return row.toDomain()
        }

        throw AuthError.profileCreationFailed
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case profileCreationFailed

    var errorDescription: String? {
        switch self {
        case .profileCreationFailed:
            return "Profil oluşturulamadı. Lütfen tekrar deneyin."
        }
    }
}

// MARK: - DB Row → Domain

private struct UserRow: Decodable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let isPrivate: Bool
    let planType: String

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case isPrivate = "is_private"
        case planType = "plan_type"
    }

    func toDomain() -> User {
        User(
            id: UUID(uuidString: id) ?? UUID(),
            username: username,
            displayName: displayName ?? username,
            bio: bio,
            avatarURL: avatarUrl.flatMap { URL(string: $0) },
            isPrivate: isPrivate,
            planType: planType == "premium" ? .premium : .free,
            createdAt: Date()
        )
    }
}
