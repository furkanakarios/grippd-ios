import Foundation

/// Supabase/PostgREST ISO8601 zaman damgalarını güvenli biçimde çözer.
///
/// Postgres, salise (fractional seconds) sıfır olduğunda onu hiç yazmaz:
///   "2026-07-11T16:24:34.582+00:00"  → saliseli
///   "2026-06-02T17:23:00+00:00"      → salisesiz
///
/// Tek bir `ISO8601DateFormatter` iki formatı birden kabul etmez:
/// `.withFractionalSeconds` verilirse salisesiz string'ler parse EDİLEMEZ.
/// Bu yüzden önce saliseli, sonra salisesiz formatter denenir.
///
/// Not: Bu tolerans olmadan, kullanıcının seçtiği (çoğu zaman tam dakikaya denk
/// gelen, yani salisesiz) `watched_at` değerleri parse edilemiyordu ve çağrı
/// yerlerindeki `?? Date()` fallback'i yüzünden tüm loglar "az önce" görünüyordu.
enum SupabaseDate {

    private static let withFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let withoutFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Her iki ISO8601 varyantını da dener; çözemezse `nil` döner.
    static func parse(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return withFractional.date(from: string) ?? withoutFractional.date(from: string)
    }

    /// Sunucuya gönderim için ISO8601 string üretir (saliseli).
    static func string(from date: Date) -> String {
        withFractional.string(from: date)
    }
}
