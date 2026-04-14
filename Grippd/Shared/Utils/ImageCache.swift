import UIKit

// MARK: - ImageCache
/// NSCache-backed in-memory image store.
/// Thread-safe via NSCache's own locking. 75 MB cap, 300 entry limit.

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 300
        c.totalCostLimit = 75 * 1024 * 1024  // 75 MB
        return c
    }()

    private init() {}

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        // cost = approx bytes (width × height × scale² × 4 channels)
        let scale = image.scale
        let cost = Int(image.size.width * image.size.height * scale * scale * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
