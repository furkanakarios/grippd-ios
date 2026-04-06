import Foundation
import Supabase

final class SupabaseClientService {
    static let shared = SupabaseClientService()

    let client: SupabaseClient

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String
        else {
            fatalError("Supabase credentials missing from Info.plist. Check xcconfig setup.")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
