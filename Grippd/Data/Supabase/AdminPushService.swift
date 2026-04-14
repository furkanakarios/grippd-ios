import Foundation
import Supabase

// MARK: - PushNotificationLog

struct PushNotificationLog: Identifiable, Decodable {
    let id: UUID
    let title: String
    let body: String
    let target: String
    let sentAt: Date
    let sentCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, body, target
        case sentAt    = "sent_at"
        case sentCount = "sent_count"
    }
}

// MARK: - AdminPushService

@MainActor
final class AdminPushService {
    static let shared = AdminPushService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    func send(title: String, body: String, target: String, sentBy: UUID) async throws -> (sent: Int, total: Int) {
        struct Payload: Encodable {
            let title: String
            let body: String
            let target: String
            let sent_by: String
        }
        struct Result: Decodable {
            let sent: Int
            let total: Int
        }
        let result: Result = try await client.functions.invoke(
            "send-push",
            options: FunctionInvokeOptions(body: Payload(
                title: title, body: body,
                target: target, sent_by: sentBy.uuidString
            ))
        )
        return (result.sent, result.total)
    }

    func fetchHistory() async throws -> [PushNotificationLog] {
        try await client
            .from("push_notifications")
            .select("id, title, body, target, sent_at, sent_count")
            .order("sent_at", ascending: false)
            .limit(20)
            .execute()
            .value
    }
}
