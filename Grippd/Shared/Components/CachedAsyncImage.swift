import SwiftUI

// MARK: - CachedAsyncImage
/// Drop-in replacement for SwiftUI's AsyncImage that uses ImageCache.
/// Cache hits are resolved synchronously in init — no placeholder flash on re-scroll.
/// Matching API: CachedAsyncImage(url:) { phase in ... }

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase

    // MARK: Init

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        // Initialise with cached image if available — avoids placeholder flash
        if let url, let cached = ImageCache.shared.image(for: url) {
            self._phase = State(initialValue: .success(Image(uiImage: cached)))
        } else {
            self._phase = State(initialValue: .empty)
        }
    }

    // MARK: Body

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    // MARK: Loading

    private func load() async {
        guard let url else { return }

        // Already cached (from another call after init)
        if let cached = ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled else { return }
            if let uiImage = UIImage(data: data) {
                ImageCache.shared.store(uiImage, for: url)
                phase = .success(Image(uiImage: uiImage))
            }
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failure(error)
        }
    }
}
