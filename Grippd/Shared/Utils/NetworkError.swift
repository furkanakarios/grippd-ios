import Foundation

/// Ağ hatalarını kullanıcıya gösterilecek anlaşılır Türkçe mesajlara çevirir.
/// URLError kodlarını (çevrimdışı, zaman aşımı, sunucuya ulaşılamıyor vb.)
/// yakalar; ağ dışı hatalarda özgün mesajı korur.
enum NetworkError {
    static func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "İnternet bağlantısı yok. Bağlantını kontrol edip tekrar dene."
            case .timedOut:
                return "Bağlantı zaman aşımına uğradı. Lütfen tekrar dene."
            case .networkConnectionLost:
                return "Bağlantı kesildi. Lütfen tekrar dene."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "Sunucuya ulaşılamıyor. Lütfen daha sonra tekrar dene."
            case .cancelled:
                return "İstek iptal edildi."
            default:
                return "Bağlantı hatası oluştu. Lütfen tekrar dene."
            }
        }
        return error.localizedDescription
    }

    /// URLError ise ağ kaynaklı (yeniden denenebilir) sayılır.
    static func isNetworkError(_ error: Error) -> Bool {
        error is URLError
    }
}
