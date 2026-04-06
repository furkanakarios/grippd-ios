import Foundation
import Supabase

// MARK: - Models

struct CommunityStats: Decodable {
    let avgRating: Double
    let reviewCount: Int

    enum CodingKeys: String, CodingKey {
        case avgRating = "avg_rating"
        case reviewCount = "review_count"
    }
}

// MARK: - Service

final class CommunityService {
    static let shared = CommunityService()
    private let db: PostgrestClient

    private init() {
        db = SupabaseClientService.shared.client.schema("public")
    }

    /// Belirli bir içerik için ortalama puan ve yorum sayısını döner.
    /// `contentKey` formatı: "movie-123", "tv-456", "book-abc123"
    func stats(for contentKey: String) async -> CommunityStats? {
        do {
            let result: [CommunityStats] = try await db
                .from("content_stats")
                .select("avg_rating, review_count")
                .eq("content_key", value: contentKey)
                .limit(1)
                .execute()
                .value
            return result.first
        } catch {
            return nil
        }
    }
}
