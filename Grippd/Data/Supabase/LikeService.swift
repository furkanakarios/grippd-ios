import Foundation
import Supabase

@MainActor
final class LikeService {
    static let shared = LikeService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Like / Unlike

    func like(logID: UUID) async throws {
        guard let myID = try? await client.auth.session.user.id else { return }
        struct Payload: Encodable {
            let user_id: String
            let log_id: String
        }
        try await client
            .from("likes")
            .upsert(Payload(user_id: myID.uuidString, log_id: logID.uuidString),
                    onConflict: "user_id,log_id")
            .execute()
    }

    func unlike(logID: UUID) async throws {
        guard let myID = try? await client.auth.session.user.id else { return }
        try await client
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

        struct CountRow: Decodable {
            let log_id: String
            let count: Int
        }
        struct MyLikeRow: Decodable {
            let log_id: String
        }

        async let countRows: [CountRow] = (try? client
            .from("likes")
            .select("log_id, count:id.count()")
            .in("log_id", values: idStrings)
            .execute()
            .value) ?? []

        async let myLikeRows: [MyLikeRow] = (try? client
            .from("likes")
            .select("log_id")
            .eq("user_id", value: myID.uuidString)
            .in("log_id", values: idStrings)
            .execute()
            .value) ?? []

        let (counts, myLikes) = await (countRows, myLikeRows)

        var result: [UUID: LikeData] = [:]
        let myLikedIDs = Set(myLikes.compactMap { UUID(uuidString: $0.log_id) })

        for row in counts {
            guard let logID = UUID(uuidString: row.log_id) else { continue }
            result[logID] = LikeData(
                logID: logID,
                count: row.count,
                isLiked: myLikedIDs.contains(logID)
            )
        }
        // Beğeni olmayan log'lar için default değer
        for logID in logIDs where result[logID] == nil {
            result[logID] = LikeData(
                logID: logID,
                count: 0,
                isLiked: myLikedIDs.contains(logID)
            )
        }
        return result
    }
}
