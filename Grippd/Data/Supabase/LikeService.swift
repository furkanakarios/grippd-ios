import Foundation
import Supabase

@MainActor
final class LikeService {
    static let shared = LikeService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Like / Unlike

    func like(logID: UUID) async {
        guard let myID = try? await client.auth.session.user.id else { return }
        struct Payload: Encodable { let user_id: String; let log_id: String }
        try? await client
            .from("likes")
            .insert(Payload(user_id: myID.uuidString, log_id: logID.uuidString))
            .execute()
    }

    func unlike(logID: UUID) async {
        guard let myID = try? await client.auth.session.user.id else { return }
        try? await client
            .from("likes")
            .delete()
            .eq("user_id", value: myID.uuidString)
            .eq("log_id", value: logID.uuidString)
            .execute()
    }

    // MARK: - Batch Fetch (Feed için)

    struct LikeData {
        let logID: UUID
        let count: Int
        let isLiked: Bool
    }

    /// Verilen log ID listesi için like sayılarını ve kullanıcının beğenip beğenmediğini çeker.
    func fetchLikeData(logIDs: [UUID], myID: UUID) async -> [UUID: LikeData] {
        guard !logIDs.isEmpty else { return [:] }
        let idStrings = logIDs.map { $0.uuidString }

        struct LikeRow: Decodable { let log_id: String; let user_id: String }

        // Tüm like'ları çek, client-side say
        async let allRows: [LikeRow] = (try? client
            .from("likes")
            .select("log_id, user_id")
            .in("log_id", values: idStrings)
            .execute()
            .value) ?? []

        let rows = await allRows

        var counts: [UUID: Int] = [:]
        var myLikedIDs = Set<UUID>()
        let myIDLower = myID.uuidString.lowercased()

        for row in rows {
            guard let logID = UUID(uuidString: row.log_id) else { continue }
            counts[logID, default: 0] += 1
            if row.user_id.lowercased() == myIDLower {
                myLikedIDs.insert(logID)
            }
        }

        var result: [UUID: LikeData] = [:]
        for logID in logIDs {
            result[logID] = LikeData(
                logID: logID,
                count: counts[logID] ?? 0,
                isLiked: myLikedIDs.contains(logID)
            )
        }
        return result
    }
}
