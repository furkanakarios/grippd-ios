import Foundation

enum BooksMapper {

    // MARK: - Google Books → Content

    static func toContent(_ book: GoogleBook) -> Content {
        Content(
            id: UUID(),
            tmdbID: nil,
            googleBooksID: book.id,
            title: book.volumeInfo.title,
            originalTitle: nil,
            overview: book.volumeInfo.description,
            posterURL: book.volumeInfo.imageLinks?.thumbnailURL,
            backdropURL: nil,
            releaseYear: book.volumeInfo.publishYear.flatMap { Int($0) },
            contentType: .book,
            genres: book.volumeInfo.categories ?? [],
            averageRating: book.volumeInfo.averageRating,
            tmdbPopularity: nil,
            runtime: book.volumeInfo.pageCount,  // kitapta runtime = sayfa sayısı
            isUserCreated: false,
            createdByUserID: nil,
            createdAt: Date()
        )
    }

    // MARK: - Open Library → Content (fallback)

    static func toContent(_ work: OpenLibraryWork) -> Content {
        Content(
            id: UUID(),
            tmdbID: nil,
            googleBooksID: nil,
            title: work.title,
            originalTitle: nil,
            overview: nil,
            posterURL: work.coverURL,
            backdropURL: nil,
            releaseYear: work.firstPublishYear,
            contentType: .book,
            genres: work.subject.map { Array($0.prefix(5)) } ?? [],
            averageRating: work.ratingsAverage,
            tmdbPopularity: nil,
            runtime: work.numberOfPagesMedian,
            isUserCreated: false,
            createdByUserID: nil,
            createdAt: Date()
        )
    }
}
