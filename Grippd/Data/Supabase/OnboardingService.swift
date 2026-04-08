import Foundation
import Supabase

final class OnboardingService {
    static let shared = OnboardingService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Username

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let rows: [[String: String]] = try await client
            .from("users")
            .select("username")
            .eq("username", value: username)
            .limit(1)
            .execute()
            .value
        return rows.isEmpty
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(
        userID: UUID,
        username: String,
        displayName: String,
        interests: [ContentInterest],
        avatarData: Data?
    ) async throws -> User {
        // 1. Upload avatar if provided
        var avatarURL: URL?
        if let data = avatarData {
            avatarURL = try await uploadAvatar(userID: userID, data: data)
        }

        // 2. Update user profile
        struct UpdatePayload: Encodable {
            let username: String
            let displayName: String
            let avatarUrl: String?
            let onboardingCompleted: Bool
            let interests: [String]
            enum CodingKeys: String, CodingKey {
                case username, interests
                case displayName = "display_name"
                case avatarUrl = "avatar_url"
                case onboardingCompleted = "onboarding_completed"
            }
        }

        let payload = UpdatePayload(
            username: username,
            displayName: displayName.isEmpty ? username : displayName,
            avatarUrl: avatarURL?.absoluteString,
            onboardingCompleted: true,
            interests: interests.map { $0.rawValue }
        )

        let rows: [UserRow] = try await client
            .from("users")
            .update(payload)
            .eq("id", value: userID.uuidString)
            .select()
            .execute()
            .value

        guard let row = rows.first else {
            throw OnboardingError.updateFailed
        }

        return row.toDomain()
    }

    // MARK: - Avatar Upload

    private func uploadAvatar(userID: UUID, data: Data) async throws -> URL {
        let path = "\(userID.uuidString)/avatar.jpg"
        try await client.storage
            .from("avatars")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))

        let urlString = try client.storage.from("avatars").getPublicURL(path: path)
        return urlString
    }

    // MARK: - Check Onboarding Status

    func needsOnboarding(userID: UUID) async throws -> Bool {
        struct Row: Decodable {
            let onboardingCompleted: Bool
            enum CodingKeys: String, CodingKey {
                case onboardingCompleted = "onboarding_completed"
            }
        }
        let rows: [Row] = try await client
            .from("users")
            .select("onboarding_completed")
            .eq("id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value

        return !(rows.first?.onboardingCompleted ?? false)
    }
}

// MARK: - Errors

enum OnboardingError: LocalizedError {
    case updateFailed

    var errorDescription: String? {
        "Profil güncellenemedi. Lütfen tekrar deneyin."
    }
}

// MARK: - User Row

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
