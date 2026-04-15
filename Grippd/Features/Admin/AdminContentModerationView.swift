import SwiftUI

// MARK: - ViewModel

@Observable
private final class AdminModerationViewModel {
    var reports: [ReportedComment] = []
    var isLoading = false
    var error: String?
    var showResolved = false

    var filtered: [ReportedComment] {
        reports.filter { showResolved ? $0.isResolved : !$0.isResolved }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            reports = try await AdminModerationService.shared.fetchReports()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func hideComment(_ report: ReportedComment, hidden: Bool) async {
        do {
            try await AdminModerationService.shared.setHidden(commentID: report.commentID, hidden: hidden)
            if let idx = reports.firstIndex(where: { $0.id == report.id }) {
                reports[idx] = ReportedComment(
                    id: reports[idx].id, reason: reports[idx].reason,
                    reportedAt: reports[idx].reportedAt, resolvedAt: reports[idx].resolvedAt,
                    commentID: reports[idx].commentID, commentBody: reports[idx].commentBody,
                    commentHidden: hidden, commentCreatedAt: reports[idx].commentCreatedAt,
                    authorID: reports[idx].authorID, authorUsername: reports[idx].authorUsername,
                    reporterUsername: reports[idx].reporterUsername
                )
            }
            HapticManager.success()
        } catch { HapticManager.error() }
    }

    func deleteComment(_ report: ReportedComment, adminID: UUID) async {
        do {
            try await AdminModerationService.shared.deleteComment(commentID: report.commentID)
            try await AdminModerationService.shared.resolveReport(reportID: report.id, adminID: adminID)
            reports.removeAll { $0.commentID == report.commentID }
            HapticManager.success()
        } catch { HapticManager.error() }
    }

    func resolveReport(_ report: ReportedComment, adminID: UUID) async {
        do {
            try await AdminModerationService.shared.resolveReport(reportID: report.id, adminID: adminID)
            if let idx = reports.firstIndex(where: { $0.id == report.id }) {
                reports[idx] = ReportedComment(
                    id: reports[idx].id, reason: reports[idx].reason,
                    reportedAt: reports[idx].reportedAt, resolvedAt: Date(),
                    commentID: reports[idx].commentID, commentBody: reports[idx].commentBody,
                    commentHidden: reports[idx].commentHidden, commentCreatedAt: reports[idx].commentCreatedAt,
                    authorID: reports[idx].authorID, authorUsername: reports[idx].authorUsername,
                    reporterUsername: reports[idx].reporterUsername
                )
            }
            HapticManager.success()
        } catch { HapticManager.error() }
    }
}

// MARK: - AdminContentModerationView

struct AdminContentModerationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AdminModerationViewModel()
    @State private var selectedReport: ReportedComment?

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: 0) {
                filterToggle
                content
            }
        }
        .navigationTitle("İçerik Moderasyonu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .sheet(item: $selectedReport) { report in
            ModerationDetailSheet(report: report) { action in
                Task {
                    guard let adminID = appState.currentUser?.id else { return }
                    switch action {
                    case .hide:    await viewModel.hideComment(report, hidden: true)
                    case .unhide:  await viewModel.hideComment(report, hidden: false)
                    case .delete:  await viewModel.deleteComment(report, adminID: adminID)
                    case .resolve: await viewModel.resolveReport(report, adminID: adminID)
                    }
                    selectedReport = nil
                }
            }
        }
    }

    // MARK: - Filter Toggle

    private var filterToggle: some View {
        HStack {
            Text(viewModel.showResolved ? "Tüm raporlar" : "Bekleyen raporlar")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Toggle("Çözülenler", isOn: $viewModel.showResolved)
                .toggleStyle(.switch)
                .tint(GrippdTheme.Colors.accent)
                .labelsHidden()
            Text("Çözülenler")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 10)
        .background(.white.opacity(0.03))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            GrippdLoadingView(label: "Raporlar yükleniyor...")
        } else if let error = viewModel.error {
            GrippdEmptyStateView(icon: "exclamationmark.triangle", title: "Hata", subtitle: error)
        } else if viewModel.filtered.isEmpty {
            GrippdEmptyStateView(
                icon: "checkmark.shield",
                title: "Rapor yok",
                subtitle: viewModel.showResolved ? "Hiç rapor bulunmuyor" : "Bekleyen rapor yok"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Özet
                    HStack {
                        Text("\(viewModel.filtered.count) rapor")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.35))
                        Spacer()
                        let hiddenCount = viewModel.filtered.filter { $0.commentHidden }.count
                        if hiddenCount > 0 {
                            Text("\(hiddenCount) gizli yorum")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.vertical, GrippdTheme.Spacing.sm)

                    ForEach(viewModel.filtered) { report in
                        ReportRow(report: report) {
                            selectedReport = report
                        }
                        Divider()
                            .background(.white.opacity(0.06))
                            .padding(.leading, GrippdTheme.Spacing.md)
                    }
                }
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
    }
}

// MARK: - ReportRow

private struct ReportRow: View {
    let report: ReportedComment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    // Durum ikonu
                    Image(systemName: report.isResolved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(report.isResolved ? .green : .orange)

                    Text("@\(report.authorUsername)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(report.reason)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12), in: Capsule())

                    Spacer()

                    if report.commentHidden {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Text(report.reportedAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Text(report.commentBody)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(report.commentHidden ? 0.3 : 0.7))
                    .lineLimit(2)
                    .strikethrough(report.commentHidden, color: .white.opacity(0.3))

                Text("Raporlayan: @\(report.reporterUsername)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ModerationDetailSheet

enum ModerationAction { case hide, unhide, delete, resolve }

private struct ModerationDetailSheet: View {
    let report: ReportedComment
    let onAction: (ModerationAction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        commentCard
                        metaSection
                        actionsSection
                    }
                    .padding(GrippdTheme.Spacing.md)
                }
            }
            .navigationTitle("Rapor Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
            .confirmationDialog("Yorumu kalıcı olarak sil?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Sil", role: .destructive) { onAction(.delete) }
                Button("İptal", role: .cancel) {}
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var commentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("@\(report.authorUsername)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if report.commentHidden {
                    Label("Gizli", systemImage: "eye.slash")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
            Text(report.commentBody)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Text(report.commentCreatedAt.formatted(.dateTime.day().month().year().hour().minute()))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(GrippdTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var metaSection: some View {
        VStack(spacing: 0) {
            infoRow(icon: "exclamationmark.triangle", label: "Sebep", value: report.reason)
            Divider().background(.white.opacity(0.06)).padding(.leading, 40)
            infoRow(icon: "person", label: "Raporlayan", value: "@\(report.reporterUsername)")
            Divider().background(.white.opacity(0.06)).padding(.leading, 40)
            infoRow(icon: "clock", label: "Rapor Tarihi",
                    value: report.reportedAt.formatted(.dateTime.day().month().year()))
            if report.isResolved {
                Divider().background(.white.opacity(0.06)).padding(.leading, 40)
                infoRow(icon: "checkmark.circle", label: "Durum", value: "Çözüldü")
            }
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            // Gizle / Göster
            Button {
                onAction(report.commentHidden ? .unhide : .hide)
            } label: {
                Label(
                    report.commentHidden ? "Yorumu Göster" : "Yorumu Gizle",
                    systemImage: report.commentHidden ? "eye" : "eye.slash"
                )
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                // Raporu Çöz
                if !report.isResolved {
                    Button { onAction(.resolve) } label: {
                        Label("Çözüldü İşaretle", systemImage: "checkmark.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                // Sil
                Button { showDeleteConfirm = true } label: {
                    Label("Yorumu Sil", systemImage: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
    }
}
