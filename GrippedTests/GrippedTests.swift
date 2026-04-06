import XCTest
@testable import Grippd

final class GrippedTests: XCTestCase {

    func testUserEntityCreation() {
        let user = User(
            id: UUID(),
            username: "testuser",
            displayName: "Test User",
            bio: nil,
            avatarURL: nil,
            bannerURL: nil,
            isPrivate: false,
            planType: .free,
            createdAt: Date()
        )
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.planType, .free)
    }

    func testLogEntryRatingBounds() {
        let entry = LogEntry(
            id: UUID(),
            userID: UUID(),
            contentID: UUID(),
            watchedAt: Date(),
            rating: 7.5,
            emojiReaction: "🔥",
            isRewatch: false,
            notes: nil,
            createdAt: Date()
        )
        XCTAssertEqual(entry.rating, 7.5)
        XCTAssertTrue((0.0...10.0).contains(entry.rating!))
    }
}
