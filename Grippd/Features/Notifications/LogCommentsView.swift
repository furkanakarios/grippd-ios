import SwiftUI

/// Bildirim navigasyonunda açılan log yorum ekranı (full navigation destination).
struct LogCommentsView: View {
    let logID: UUID
    @Environment(AppState.self) private var appState

    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var isSending = false
    @State private var draftText = ""
    @State private var monthlyCount = 0
    @State private var showPaywall = false
    @FocusState private var isInputFocused: Bool

    private var isPremium: Bool { appState.isPremium }
    private var isLimitReached: Bool { !PremiumGate.isAllowed(.postComment(monthlyCount: monthlyCount), isPremium: isPremium) }
    private var remainingComments: Int { PremiumGate.remaining(.postComment(monthlyCount: monthlyCount), isPremium: isPremium) ?? 0 }

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: 0) {
                commentsList
                Divider().background(.white.opacity(0.08))
                if isLimitReached {
                    lockedBar
                } else {
                    inputBar
                }
            }
        }
        .navigationTitle("Yorumlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView()
        }
    }

    // MARK: - List

    private var commentsList: some View {
        Group {
            if isLoading {
                Spacer()
                ProgressView().tint(GrippdTheme.Colors.accent)
                Spacer()
            } else if comments.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("Henüz yorum yok")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(comments) { comment in
                            LogCommentRow(comment: comment) {
                                toggleLike(comment)
                            } onDelete: {
                                Task { await delete(comment) }
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
            if !isPremium && remainingComments <= 5 {
                Text("\(remainingComments) yorum hakkın kaldı")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
            }
            HStack(spacing: 10) {
                TextField("Yorum yaz...", text: $draftText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(GrippdTheme.Colors.surface, in: RoundedRectangle(cornerRadius: 20))

                if isSending {
                    ProgressView().tint(GrippdTheme.Colors.accent).frame(width: 36, height: 36)
                } else {
                    Button { Task { await send() } } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .white.opacity(0.2) : GrippdTheme.Colors.accent
                            )
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
        }
    }

    private var lockedBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 13)).foregroundStyle(.orange)
                Text("Bu ayki yorum hakkını (\(PremiumGate.maxFreeCommentsPerMonth)) kullandın")
                    .font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
            }
            Button { showPaywall = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill").font(.system(size: 13))
                    Text("Premium'a Geç — Sınırsız Yorum")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(GrippdTheme.Colors.background)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
        .padding(.vertical, 12).padding(.bottom, 4)
    }

    // MARK: - Actions

    private func load() async {
        isLoading = true
        async let fetchedComments = CommentService.shared.fetchComments(logID: logID)
        async let count = CommentService.shared.monthlyCommentCount()
        let (c, mc) = await ((try? fetchedComments) ?? [], count)
        comments = c
        monthlyCount = mc
        isLoading = false
    }

    private func send() async {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending, !isLimitReached else { return }
        isSending = true
        draftText = ""
        do {
            let comment = try await CommentService.shared.addComment(logID: logID, body: trimmed)
            comments.append(comment)
            monthlyCount += 1
        } catch {
            draftText = trimmed
        }
        isSending = false
    }

    private func delete(_ comment: Comment) async {
        guard let idx = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        comments.remove(at: idx)
        try? await CommentService.shared.deleteComment(commentID: comment.id)
    }

    private func toggleLike(_ comment: Comment) {
        guard let idx = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        let wasLiked = comments[idx].isLiked
        comments[idx].isLiked = !wasLiked
        comments[idx].likeCount += wasLiked ? -1 : 1
        Task {
            do {
                if wasLiked { try await CommentService.shared.unlikeComment(commentID: comment.id) }
                else { try await CommentService.shared.likeComment(commentID: comment.id) }
            } catch {
                if let i = comments.firstIndex(where: { $0.id == comment.id }) {
                    comments[i].isLiked = wasLiked
                    comments[i].likeCount += wasLiked ? 1 : -1
                }
            }
        }
    }
}

// MARK: - Comment Row (standalone)

private struct LogCommentRow: View {
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
        default:         return comment.createdAt.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: comment.user.avatarURL) { phase in
                if case .success(let image) = phase { image.resizable().scaledToFill() }
                else {
                    Circle().fill(GrippdTheme.Colors.accent.opacity(0.12))
                        .overlay(Image(systemName: "person.fill").font(.system(size: 12)).foregroundStyle(.white.opacity(0.3)))
                }
            }
            .frame(width: 34, height: 34).clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.user.displayName).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    Text(relativeTime).font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Button(action: onLike) {
                        HStack(spacing: 3) {
                            Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundStyle(comment.isLiked ? .red : .white.opacity(0.3))
                            if comment.likeCount > 0 {
                                Text(verbatim: "\(comment.likeCount)").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                            }
                        }
                    }.buttonStyle(.plain)
                    if comment.isOwn {
                        Button(action: onDelete) {
                            Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.white.opacity(0.25))
                        }.buttonStyle(.plain)
                    }
                }
                Text(comment.body).font(.system(size: 14)).foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
    }
}
