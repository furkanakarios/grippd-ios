import Foundation
import SwiftUI

// MARK: - Search Response

struct WatchmodeSearchResponse: Decodable {
    let titleResults: [WatchmodeTitleResult]

    enum CodingKeys: String, CodingKey {
        case titleResults = "title_results"
    }
}

struct WatchmodeTitleResult: Decodable {
    let id: Int
    let name: String
    let type: String   // "movie" | "tv_series"
    let year: Int?
    let tmdbID: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, type, year
        case tmdbID = "tmdb_id"
    }
}

// MARK: - Source (Streaming Platform)

struct WatchmodeSource: Decodable, Identifiable {
    let sourceID: Int
    let name: String
    let type: SourceType
    let region: String
    let webURL: String?
    let iosURL: String?
    let format: String?   // "SD", "HD", "4K"
    let price: Double?

    var id: Int { sourceID }

    enum CodingKeys: String, CodingKey {
        case name, type, region, format, price
        case sourceID = "source_id"
        case webURL = "web_url"
        case iosURL = "ios_url"
    }

    enum SourceType: String, Decodable {
        case subscription = "sub"
        case rent = "rent"
        case buy = "buy"
        case free = "free"
        case tve = "tve"      // TV Everywhere (cable subscriber)
        case unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = SourceType(rawValue: raw) ?? .unknown
        }

        var displayName: String {
            switch self {
            case .subscription: return "Abone"
            case .rent: return "Kiralık"
            case .buy: return "Satın Al"
            case .free: return "Ücretsiz"
            case .tve: return "Kablo"
            case .unknown: return ""
            }
        }

        var color: Color {
            switch self {
            case .subscription: return Color(red: 0.2, green: 0.78, blue: 0.45)
            case .rent: return Color(red: 0.91, green: 0.70, blue: 0.29)   // accent
            case .buy: return Color(red: 0.4, green: 0.6, blue: 1.0)
            case .free: return Color(red: 0.4, green: 0.8, blue: 0.9)
            case .tve, .unknown: return .white.opacity(0.5)
            }
        }
    }

    // Platform brand color for chip background
    var platformColor: Color {
        switch name.lowercased() {
        case let n where n.contains("netflix"): return Color(red: 0.9, green: 0.1, blue: 0.1)
        case let n where n.contains("disney"): return Color(red: 0.05, green: 0.18, blue: 0.55)
        case let n where n.contains("prime"), let n where n.contains("amazon"): return Color(red: 0.0, green: 0.46, blue: 0.75)
        case let n where n.contains("apple"): return Color(red: 0.35, green: 0.35, blue: 0.38)
        case let n where n.contains("mubi"): return Color(red: 0.0, green: 0.48, blue: 0.4)
        case let n where n.contains("blutv"): return Color(red: 0.42, green: 0.15, blue: 0.75)
        case let n where n.contains("gain"): return Color(red: 0.85, green: 0.25, blue: 0.1)
        case let n where n.contains("exxen"): return Color(red: 0.75, green: 0.1, blue: 0.15)
        case let n where n.contains("hbo"), let n where n.contains("max"): return Color(red: 0.45, green: 0.05, blue: 0.75)
        case let n where n.contains("hulu"): return Color(red: 0.1, green: 0.78, blue: 0.48)
        default: return Color(red: 0.22, green: 0.22, blue: 0.26)
        }
    }
}

// MARK: - Cached Entry

struct WatchmodeCacheEntry {
    let sources: [WatchmodeSource]
    let fetchedAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > 86_400  // 24 saat
    }
}
