import Foundation
import Supabase

// MARK: - Domain Model

struct Comment: Identifiable {
    let id: UUID
    let logID: UUID
    let user: CommentUser
    let body: String
    let createdAt: Date
    var likeCount: Int
    var isLiked: Bool
    var isOwn: Bool
}

struct CommentUser: Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: URL?
}

// MARK: - Service

@MainActor
final class CommentService {
    static let shared = CommentService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Fetch

    func fetchComments(logID: UUID) async throws -> [Comment] {
        guard let myID = try? await client.auth.session.user.id else { return [] }

        struct Row: Decodable {
            let id: String
            let logId: String
            let body: String
            let createdAt: String
            let user: UserSnippet

            enum CodingKeys: String, CodingKey {
                case id, body, user
                case logId = "log_id"
                case createdAt = "created_at"
            }

            struct UserSnippet: Decodable {
                let id: String
                let username: String
                let displayName: String?
                let avatarUrl: String?
                enum CodingKeys: String, CodingKey {
                    case id, username
                    case displayName = "display_name"
                    case avatarUrl = "avatar_url"
                }
            }
        }

        let rows: [Row] = try await client
            .from("comments")
            .select("id, log_id, body, created_at, user:user_id(id, username, display_name, avatar_url)")
            .eq("log_id", value: logID.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        let commentIDs = rows.compactMap { UUID(uuidString: $0.id) }
        let likeData = await fetchCommentLikeData(commentIDs: commentIDs, myID: myID)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return rows.compactMap { row in
            guard let commentID = UUID(uuidString: row.id),
                  let userID = UUID(uuidString: row.user.id) else { return nil }
            let date = formatter.date(from: row.createdAt) ?? Date()
            let like = likeData[commentID]
            return Comment(
                id: commentID,
                logID: UUID(uuidString: row.logId) ?? logID,
                user: CommentUser(
                    id: userID,
                    username: row.user.username,
                    displayName: row.user.displayName ?? row.user.username,
                    avatarURL: row.user.avatarUrl.flatMap { URL(string: $0) }
                ),
                body: row.body,
                createdAt: date,
                likeCount: like?.count ?? 0,
                isLiked: like?.isLiked ?? false,
                isOwn: userID == myID
            )
        }
    }

    // MARK: - Add / Delete

    func addComment(logID: UUID, body: String) async throws -> Comment {
        guard let myID = try? await client.auth.session.user.id else {
            throw CommentError.notAuthenticated
        }
        struct Payload: Encodable {
            let user_id: String
            let log_id: String
            let body: String
        }
        struct Row: Decodable {
            let id: String
            let logId: String
            let body: String
            let createdAt: String
            enum CodingKeys: String, CodingKey {
                case id, body
                case logId = "log_id"
                case createdAt = "created_at"
            }
        }
        let rows: [Row] = try await client
            .from("comments")
            .insert(Payload(user_id: myID.uuidString, log_id: logID.uuidString, body: body))
            .select()
            .execute()
            .value

        guard let row = rows.first,
              let commentID = UUID(uuidString: row.id) else {
            throw CommentError.insertFailed
        }

        // Kendi profilimizi çek
        let userRows: [UserRow] = try await client
            .from("users")
            .select()
            .eq("id", value: myID.uuidString)
            .limit(1)
            .execute()
            .value

        let me = userRows.first?.toDomain()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return Comment(
            id: commentID,
            logID: UUID(uuidString: row.logId) ?? logID,
            user: CommentUser(
                id: myID,
                username: me?.username ?? "",
                displayName: me?.displayName ?? "",
                avatarURL: me?.avatarURL
            ),
            body: row.body,
            createdAt: formatter.date(from: row.createdAt) ?? Date(),
            likeCount: 0,
            isLiked: false,
            isOwn: true
        )
    }

    func deleteComment(commentID: UUID) async throws {
        try await client
            .from("comments")
            .delete()
            .eq("id", value: commentID.uuidString)
            .execute()
    }

    // MARK: - Monthly Limit

    static var freeMonthlyLimit: Int { PremiumGate.maxFreeCommentsPerMonth }

    /// Kullanıcının bu ay yaptığı yorum sayısını döner.
    func monthlyCommentCount() async -> Int {
        guard let myID = try? await client.auth.session.user.id else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return 0 }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startString = formatter.string(from: startOfMonth)

        struct CountRow: Decodable { let id: String }
        let rows: [CountRow] = (try? await client
            .from("comments")
            .select("id")
            .eq("user_id", value: myID.uuidString)
            .gte("created_at", value: startString)
            .execute()
            .value) ?? []

        return rows.count
    }

    // MARK: - Comment Count (batch, feed için)

    func fetchCommentCounts(logIDs: [UUID]) async -> [UUID: Int] {
        guard !logIDs.isEmpty else { return [:] }
        struct Row: Decodable { let log_id: String }
        let rows: [Row] = (try? await client
            .from("comments")
            .select("log_id")
            .in("log_id", values: logIDs.map { $0.uuidString })
            .execute()
            .value) ?? []

        var result: [UUID: Int] = [:]
        for row in rows {
            if let id = UUID(uuidString: row.log_id) {
                result[id, default: 0] += 1
            }
        }
        return result
    }

    // MARK: - Comment Like / Unlike

    func likeComment(commentID: UUID) async throws {
        guard let myID = try? await client.auth.session.user.id else { return }
        struct Payload: Encodable { let user_id: String; let comment_id: String }
        do {
            try await client
                .from("comment_likes")
                .insert(Payload(user_id: myID.uuidString, comment_id: commentID.uuidString))
                .execute()
        } catch {
            let msg = error.localizedDescription.lowercased()
            guard msg.contains("23505") || msg.contains("duplicate") || msg.contains("unique") else {
                throw error
            }
        }
    }

    func unlikeComment(commentID: UUID) async throws {
        guard let myID = try? await client.auth.session.user.id else { return }
        try await client
            .from("comment_likes")
            .delete()
            .eq("user_id", value: myID.uuidString)
            .eq("comment_id", value: commentID.uuidString)
            .execute()
    }

    // MARK: - Private Helpers

    private struct CommentLikeData { let count: Int; let isLiked: Bool }

    private func fetchCommentLikeData(commentIDs: [UUID], myID: UUID) async -> [UUID: CommentLikeData] {
        guard !commentIDs.isEmpty else { return [:] }
        let idStrings = commentIDs.map { $0.uuidString }

        struct CountRow: Decodable { let comment_id: String; let count: Int }
        struct MyLikeRow: Decodable { let comment_id: String }

        async let countRows: [CountRow] = (try? client
            .from("comment_likes")
            .select("comment_id, count:id.count()")
            .in("comment_id", values: idStrings)
            .execute()
            .value) ?? []

        async let myLikeRows: [MyLikeRow] = (try? client
            .from("comment_likes")
            .select("comment_id")
            .eq("user_id", value: myID.uuidString)
            .in("comment_id", values: idStrings)
            .execute()
            .value) ?? []

        let (counts, myLikes) = await (countRows, myLikeRows)
        let myLikedIDs = Set(myLikes.compactMap { UUID(uuidString: $0.comment_id) })

        var result: [UUID: CommentLikeData] = [:]
        for row in counts {
            if let id = UUID(uuidString: row.comment_id) {
                result[id] = CommentLikeData(count: row.count, isLiked: myLikedIDs.contains(id))
            }
        }
        return result
    }
}

// MARK: - Errors

enum CommentError: LocalizedError {
    case notAuthenticated, insertFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Giriş yapman gerekiyor."
        case .insertFailed:     return "Yorum gönderilemedi."
        }
    }
}
