import SwiftUI

// MARK: - ViewModel

@Observable
private final class CommentsViewModel {
    var comments: [Comment] = []
    var isLoading = false
    var isSending = false
    var draftText = ""
    var error: String?

    // Limit tracking
    var monthlyCount: Int = 0
    var isPremium: Bool = false
    var isLimitReached: Bool { !isPremium && monthlyCount >= CommentService.freeMonthlyLimit }
    var remainingComments: Int { max(0, CommentService.freeMonthlyLimit - monthlyCount) }

    func load(logID: UUID, isPremium: Bool) async {
        self.isPremium = isPremium
        isLoading = true
        async let fetchedComments = CommentService.shared.fetchComments(logID: logID)
        async let fetchedCount = CommentService.shared.monthlyCommentCount()
        let (c, count) = await (try? fetchedComments, fetchedCount)
        comments = c ?? []
        monthlyCount = count
        isLoading = false
    }

    func send(logID: UUID) async {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending, !isLimitReached else { return }
        isSending = true
        draftText = ""
        do {
            let comment = try await CommentService.shared.addComment(logID: logID, body: trimmed)
            comments.append(comment)
            monthlyCount += 1
        } catch {
            self.error = error.localizedDescription
            draftText = trimmed // restore on failure
        }
        isSending = false
    }

    func delete(comment: Comment) async {
        guard let idx = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        comments.remove(at: idx)
        try? await CommentService.shared.deleteComment(commentID: comment.id)
    }

    func toggleLike(commentID: UUID) async {
        guard let idx = comments.firstIndex(where: { $0.id == commentID }) else { return }
        let wasLiked = comments[idx].isLiked
        comments[idx].isLiked = !wasLiked
        comments[idx].likeCount += wasLiked ? -1 : 1
        do {
            if wasLiked {
                try await CommentService.shared.unlikeComment(commentID: commentID)
            } else {
                try await CommentService.shared.likeComment(commentID: commentID)
            }
        } catch {
            comments[idx].isLiked = wasLiked
            comments[idx].likeCount += wasLiked ? 1 : -1
        }
    }
}

// MARK: - View

struct CommentsSheetView: View {
    let logID: UUID
    let contentTitle: String
    let isPremium: Bool
    @Binding var commentCount: Int

    @State private var viewModel = CommentsViewModel()
    @State private var showPaywall = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                VStack(spacing: 0) {
                    commentsList
                    Divider().background(.white.opacity(0.08))
                    if viewModel.isLimitReached {
                        lockedInputBar
                    } else {
                        inputBar
                    }
                }
            }
            .navigationTitle("Yorumlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await viewModel.load(logID: logID, isPremium: isPremium) }
        .onChange(of: viewModel.comments.count) { _, newCount in
            commentCount = newCount
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView()
        }
    }

    // MARK: - List

    private var commentsList: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView().tint(GrippdTheme.Colors.accent)
                Spacer()
            } else if viewModel.comments.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("Henüz yorum yok")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("İlk yorumu sen yap!")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.2))
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.comments) { comment in
                            CommentRow(comment: comment) {
                                Task { await viewModel.toggleLike(commentID: comment.id) }
                            } onDelete: {
                                Task { await viewModel.delete(comment: comment) }
                            }
                            Divider().background(.white.opacity(0.06))
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Kalan hak göstergesi (son 5'te uyar)
            if !isPremium && viewModel.remainingComments <= 5 {
                Text("\(viewModel.remainingComments) yorum hakkın kaldı")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
            }

            HStack(spacing: 10) {
                TextField("Yorum yaz...", text: $viewModel.draftText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(GrippdTheme.Colors.surface, in: RoundedRectangle(cornerRadius: 20))

                if viewModel.isSending {
                    ProgressView()
                        .tint(GrippdTheme.Colors.accent)
                        .frame(width: 36, height: 36)
                } else {
                    Button {
                        Task { await viewModel.send(logID: logID) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .white.opacity(0.2)
                                : GrippdTheme.Colors.accent
                            )
                    }
                    .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Locked Input Bar (limit doldu)

    private var lockedInputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text("Bu ayki yorum hakkını (20) kullandın")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13))
                    Text("Premium'a Geç — Sınırsız Yorum")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(GrippdTheme.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    let comment: Comment
    let onLike: () -> Void
    let onDelete: () -> Void

    private var relativeTime: String {
        let diff = Date().timeIntervalSince(comment.createdAt)
        switch diff {
        case ..<60:      return "az önce"
        case ..<3600:    return "\(Int(diff/60))d önce"
        case ..<86400:   return "\(Int(diff/3600))s önce"
        case ..<604800:  return "\(Int(diff/86400))g önce"
        default:
            return comment.createdAt.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            UserAvatarView(
                url: comment.user.avatarURL,
                size: 34
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.user.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(relativeTime)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()

                    // Like butonu
                    Button(action: onLike) {
                        HStack(spacing: 3) {
                            Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundStyle(comment.isLiked ? .red : .white.opacity(0.3))
                            if comment.likeCount > 0 {
                                Text(verbatim: "\(comment.likeCount)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Silme (sadece kendi yorumu)
                    if comment.isOwn {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(comment.body)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
    }
}
