import SwiftUI

// MARK: - LogHistorySection

struct LogHistorySection: View {
    let logs: [LogEntry]
    let contentType: Content.ContentType
    var onDelete: ((LogEntry) -> Void)?

    private var watchLabel: String {
        contentType == .book ? "okuma" : "izleme"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Başlık
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GrippdTheme.Colors.accent)
                Text("Geçmiş (\(logs.count) \(watchLabel))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(1.0)
            }

            VStack(spacing: 0) {
                ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                    LogHistoryRow(log: log, onDelete: { onDelete?(log) })

                    if index < logs.count - 1 {
                        Divider()
                            .background(.white.opacity(0.06))
                            .padding(.leading, 16)
                    }
                }
            }
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - LogHistoryRow

private struct LogHistoryRow: View {
    let log: LogEntry
    var onDelete: (() -> Void)?

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            // Sol: tarih
            VStack(alignment: .leading, spacing: 2) {
                Text(log.watchedAt.formatted(.dateTime.day().month(.abbreviated).year()))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 6) {
                    if log.isRewatch {
                        Label("Tekrar", systemImage: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.8))
                    }
                    if let platform = log.platform {
                        HStack(spacing: 3) {
                            Image(systemName: platform.icon)
                                .font(.system(size: 10))
                            Text(platform.displayName)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            // Sağ: emoji + puan
            HStack(spacing: 6) {
                if let emoji = log.emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                if let rating = log.rating {
                    StarRatingBadge(rating: rating, fontSize: 12)
                }
            }

            // Sil butonu
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .confirmationDialog("Bu logu sil?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Sil", role: .destructive) { onDelete?() }
                Button("Vazgeç", role: .cancel) {}
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
