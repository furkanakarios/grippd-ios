import Foundation
import Supabase

// MARK: - CuratedCollectionRow

struct CuratedCollectionRow: Identifiable, Decodable {
    let id: String
    var title: String
    var subtitle: String
    var icon: String
    var accentHex: String
    var sortOrder: Int
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, icon
        case accentHex  = "accent_hex"
        case sortOrder  = "sort_order"
        case isActive   = "is_active"
    }
}

// MARK: - AdminCuratedListsService

@MainActor
final class AdminCuratedListsService {
    static let shared = AdminCuratedListsService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    func fetchAll() async throws -> [CuratedCollectionRow] {
        try await client
            .from("curated_collections")
            .select()
            .order("sort_order")
            .execute()
            .value
    }

    func update(_ row: CuratedCollectionRow) async throws {
        struct Payload: Encodable {
            let title: String
            let subtitle: String
            let icon: String
            let accentHex: String
            let sortOrder: Int
            let isActive: Bool
            enum CodingKeys: String, CodingKey {
                case title, subtitle, icon
                case accentHex  = "accent_hex"
                case sortOrder  = "sort_order"
                case isActive   = "is_active"
            }
        }
        let payload = Payload(
            title: row.title, subtitle: row.subtitle,
            icon: row.icon, accentHex: row.accentHex,
            sortOrder: row.sortOrder, isActive: row.isActive
        )
        try await client
            .from("curated_collections")
            .update(payload)
            .eq("id", value: row.id)
            .execute()
    }

    func setActive(_ id: String, active: Bool) async throws {
        try await client
            .from("curated_collections")
            .update(["is_active": active])
            .eq("id", value: id)
            .execute()
    }

    func moveSortOrder(rows: [CuratedCollectionRow]) async throws {
        for (idx, row) in rows.enumerated() {
            try await client
                .from("curated_collections")
                .update(["sort_order": idx + 1])
                .eq("id", value: row.id)
                .execute()
        }
    }
}
