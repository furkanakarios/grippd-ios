import Foundation

enum SupabaseConstants {
    static var projectURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? ""
    }
    static var anonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
    }
}
