import Foundation

// Bu değerler Faz 1 Step 3'te .xcconfig'den okunacak
// Şimdilik placeholder
enum SupabaseConstants {
    static var projectURL: String {
        Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    }
    static var anonKey: String {
        Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
    }
}
