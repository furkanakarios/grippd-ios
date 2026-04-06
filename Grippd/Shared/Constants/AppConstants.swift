import Foundation

enum AppConstants {

    enum API {
        static let tmdbBaseURL = "https://api.themoviedb.org/3"
        static let tmdbImageBaseURL = "https://image.tmdb.org/t/p"
        static let googleBooksBaseURL = "https://www.googleapis.com/books/v1"
        static let openLibraryBaseURL = "https://openlibrary.org"
        static let watchmodeBaseURL = "https://api.watchmode.com/v1"
    }

    enum Limits {
        static let freeMonthlyComments = 20
        static let freeMaxLists = 3
        static let freemiumPriceMonthly = 9.99
    }

    enum ImageSize {
        static let posterSmall = "w185"
        static let posterMedium = "w342"
        static let posterLarge = "w500"
        static let backdrop = "w780"
        static let original = "original"
    }

    enum Cache {
        static let streamingAvailabilityTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 gün
    }
}
