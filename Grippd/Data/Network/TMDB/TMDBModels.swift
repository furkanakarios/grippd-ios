import Foundation

// MARK: - TMDB Movie

struct TMDBMovie: Decodable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let genreIds: [Int]?
    let genres: [TMDBGenre]?
    let runtime: Int?
    let popularity: Double
    let credits: TMDBCredits?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, popularity, genres, credits
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genreIds = "genre_ids"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }

    var releaseYear: String? {
        releaseDate.flatMap { $0.split(separator: "-").first.map(String.init) }
    }
}

// MARK: - TMDB TV Show

struct TMDBTVShow: Decodable, Identifiable {
    let id: Int
    let name: String
    let originalName: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let lastAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let genreIds: [Int]?
    let genres: [TMDBGenre]?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let popularity: Double
    let seasons: [TMDBSeason]?
    let createdBy: [TMDBShowCreator]?
    let credits: TMDBCredits?
    let inProduction: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, popularity, genres, seasons, credits
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genreIds = "genre_ids"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case createdBy = "created_by"
        case inProduction = "in_production"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }

    var firstAirYear: String? {
        firstAirDate.flatMap { $0.split(separator: "-").first.map(String.init) }
    }

    var lastAirYear: String? {
        lastAirDate.flatMap { $0.split(separator: "-").first.map(String.init) }
    }

    var airYearRange: String? {
        guard let first = firstAirYear else { return nil }
        if inProduction == true { return "\(first) – devam ediyor" }
        if let last = lastAirYear, last != first { return "\(first) – \(last)" }
        return first
    }

    var mainSeasons: [TMDBSeason] {
        (seasons ?? []).filter { $0.seasonNumber > 0 }
    }
}

// MARK: - TMDB Season

struct TMDBSeason: Decodable, Identifiable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let overview: String
    let posterPath: String?
    let episodeCount: Int?
    let airDate: String?
    let episodes: [TMDBEpisode]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, episodes
        case seasonNumber = "season_number"
        case posterPath = "poster_path"
        case episodeCount = "episode_count"
        case airDate = "air_date"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }
}

// MARK: - TMDB Episode

struct TMDBEpisode: Decodable, Identifiable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String
    let stillPath: String?
    let airDate: String?
    let runtime: Int?
    let voteAverage: Double
    let voteCount: Int?
    let guestStars: [TMDBCastMember]?
    let crew: [TMDBCrewMember]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime, crew
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case stillPath = "still_path"
        case airDate = "air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case guestStars = "guest_stars"
    }

    var stillURL: URL? {
        guard let path = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    var formattedAirDate: String? {
        guard let airDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: airDate) else { return airDate }
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    var formattedRuntime: String? {
        guard let runtime, runtime > 0 else { return nil }
        let h = runtime / 60, m = runtime % 60
        if h == 0 { return "\(m)dk" }
        if m == 0 { return "\(h)s" }
        return "\(h)s \(m)dk"
    }

    var directors: [TMDBCrewMember] {
        crew?.filter { $0.job == "Director" } ?? []
    }

    var writers: [TMDBCrewMember] {
        crew?.filter { $0.department == "Writing" } ?? []
    }
}

// MARK: - TMDB Genre

struct TMDBGenre: Decodable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - TMDB Search Result (multi)

enum TMDBSearchResult: Decodable, Identifiable {
    case movie(TMDBMovie)
    case tv(TMDBTVShow)
    case unknown

    var id: String {
        switch self {
        case .movie(let m): return "movie_\(m.id)"
        case .tv(let t): return "tv_\(t.id)"
        case .unknown: return UUID().uuidString
        }
    }

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mediaType = try container.decode(String.self, forKey: .mediaType)
        switch mediaType {
        case "movie": self = .movie(try TMDBMovie(from: decoder))
        case "tv":    self = .tv(try TMDBTVShow(from: decoder))
        default:      self = .unknown
        }
    }
}

// MARK: - TMDB Show Creator

struct TMDBShowCreator: Decodable, Identifiable {
    let id: Int
    let name: String
    let profilePath: String?

    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePath = "profile_path"
    }
}

// MARK: - TMDB Credits

struct TMDBCredits: Decodable {
    let cast: [TMDBCastMember]
    let crew: [TMDBCrewMember]
}

struct TMDBCastMember: Decodable {
    let id: Int
    let creditID: String
    let name: String
    let character: String
    let profilePath: String?
    let order: Int

    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case creditID = "credit_id"
        case profilePath = "profile_path"
    }
}

struct TMDBCrewMember: Decodable {
    let id: Int
    let creditID: String
    let name: String
    let job: String
    let department: String
    let profilePath: String?

    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case creditID = "credit_id"
        case profilePath = "profile_path"
    }
}

// MARK: - TMDB Person

struct TMDBPerson: Decodable, Identifiable {
    let id: Int
    let name: String
    let profilePath: String?
    let knownForDepartment: String?
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id, name, popularity
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
    }

    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    var departmentDisplay: String {
        switch knownForDepartment {
        case "Acting": return "Oyuncu"
        case "Directing": return "Yönetmen"
        case "Writing": return "Senarist"
        case "Production": return "Yapımcı"
        case "Sound": return "Ses"
        case "Camera": return "Görüntü Yönetmeni"
        default: return knownForDepartment ?? "Sanatçı"
        }
    }
}

// MARK: - Paginated Response

struct TMDBPagedResponse<T: Decodable>: Decodable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
