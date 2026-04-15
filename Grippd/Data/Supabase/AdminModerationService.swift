import Foundation
import Supabase

// MARK: - ReportedComment

struct ReportedComment: Identifiable {
    let id: UUID           // report_id
    let reason: String
    let reportedAt: Date
    let resolvedAt: Date?

    let commentID: UUID
    let commentBody: String
    let commentHidden: Bool
    let commentCreatedAt: Date

    let authorID: UUID
    let authorUsername: String

    let reporterUsername: String

    var isResolved: Bool { resolvedAt != nil }
}

// MARK: - AdminModerationService

@MainActor
final class AdminModerationService {
    static let shared = AdminModerationService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    // MARK: - Fetch reports

    func fetchReports() async throws -> [ReportedComment] {
        struct Row: Decodable {
            let reportId: String
            let reason: String
            let reportedAt: String
            let resolvedAt: String?
            let commentId: String
            let commentBody: String
            let commentHidden: Bool
            let commentCreated: String
            let authorId: String
            let authorUsername: String
            let reporterId: String
            let reporterUsername: String

            enum CodingKeys: String, CodingKey {
                case reportId        = "report_id"
                case reason
                case reportedAt      = "reported_at"
                case resolvedAt      = "resolved_at"
                case commentId       = "comment_id"
                case commentBody     = "comment_body"
                case commentHidden   = "comment_hidden"
                case commentCreated  = "comment_created"
                case authorId        = "author_id"
                case authorUsername  = "author_username"
                case reporterId      = "reporter_id"
                case reporterUsername = "reporter_username"
            }
        }

        let rows: [Row] = try await client
            .rpc("admin_get_reports")
            .execute()
            .value

        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return rows.map { row in
            ReportedComment(
                id: UUID(uuidString: row.reportId) ?? UUID(),
                reason: row.reason,
                reportedAt: fmt.date(from: row.reportedAt) ?? Date(),
                resolvedAt: row.resolvedAt.flatMap { fmt.date(from: $0) },
                commentID: UUID(uuidString: row.commentId) ?? UUID(),
                commentBody: row.commentBody,
                commentHidden: row.commentHidden,
                commentCreatedAt: fmt.date(from: row.commentCreated) ?? Date(),
                authorID: UUID(uuidString: row.authorId) ?? UUID(),
                authorUsername: row.authorUsername,
                reporterUsername: row.reporterUsername
            )
        }
    }

    // MARK: - Hide / Unhide comment

    func setHidden(commentID: UUID, hidden: Bool) async throws {
        try await client
            .from("comments")
            .update(["is_hidden": hidden])
            .eq("id", value: commentID.uuidString)
            .execute()
    }

    // MARK: - Delete comment

    func deleteComment(commentID: UUID) async throws {
        try await client
            .from("comments")
            .delete()
            .eq("id", value: commentID.uuidString)
            .execute()
    }

    // MARK: - Resolve report

    func resolveReport(reportID: UUID, adminID: UUID) async throws {
        try await client
            .from("reports")
            .update([
                "resolved_at": ISO8601DateFormatter().string(from: Date()),
                "resolved_by": adminID.uuidString
            ])
            .eq("id", value: reportID.uuidString)
            .execute()
    }
}
