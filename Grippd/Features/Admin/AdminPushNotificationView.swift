import SwiftUI

// MARK: - ViewModel

@Observable
private final class AdminPushViewModel {
    var title = ""
    var body = ""
    var isSending = false
    var lastResult: String?
    var history: [PushNotificationLog] = []
    var error: String?

    var canSend: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                        !body.trimmingCharacters(in: .whitespaces).isEmpty }

    func send(adminID: UUID) async {
        isSending = true
        error = nil
        lastResult = nil
        do {
            let (sent, total) = try await AdminPushService.shared.send(
                title: title, body: body, target: "all", sentBy: adminID
            )
            lastResult = "\(total) cihazdan \(sent) tanesine gönderildi"
            title = ""
            body = ""
            await loadHistory()
            HapticManager.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
        isSending = false
    }

    func loadHistory() async {
        history = (try? await AdminPushService.shared.fetchHistory()) ?? []
    }
}

// MARK: - AdminPushNotificationView

struct AdminPushNotificationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AdminPushViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    composeSection
                    if !viewModel.history.isEmpty { historySection }
                }
                .padding(GrippdTheme.Spacing.md)
            }
        }
        .navigationTitle("Push Bildirim Gönder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.loadHistory() }
    }

    // MARK: - Compose

    private var composeSection: some View {
        VStack(spacing: 0) {
            // Başlık
            VStack(alignment: .leading, spacing: 6) {
                Text("Başlık")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                TextField("Bildirim başlığı", text: $viewModel.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
            }
            .padding(GrippdTheme.Spacing.md)

            Divider().background(.white.opacity(0.06))

            // Mesaj
            VStack(alignment: .leading, spacing: 6) {
                Text("Mesaj")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                TextField("Bildirim mesajı", text: $viewModel.body, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
                    .autocorrectionDisabled()
            }
            .padding(GrippdTheme.Spacing.md)

            Divider().background(.white.opacity(0.06))

            // Önizleme
            if !viewModel.title.isEmpty || !viewModel.body.isEmpty {
                notificationPreview
                    .padding(GrippdTheme.Spacing.md)
                Divider().background(.white.opacity(0.06))
            }

            // Hedef & Gönder
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Tüm kullanıcılar")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Button {
                    guard let adminID = appState.currentUser?.id else { return }
                    Task { await viewModel.send(adminID: adminID) }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 80, height: 36)
                    } else {
                        Label("Gönder", systemImage: "paperplane.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(
                                viewModel.canSend ? GrippdTheme.Colors.accent : Color.white.opacity(0.1),
                                in: Capsule()
                            )
                    }
                }
                .disabled(!viewModel.canSend || viewModel.isSending)
                .buttonStyle(.plain)
            }
            .padding(GrippdTheme.Spacing.md)
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md).stroke(.white.opacity(0.06), lineWidth: 1))
        .overlay(resultOverlay, alignment: .bottom)
    }

    private var notificationPreview: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(GrippdTheme.Colors.accent.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.title.isEmpty ? "Başlık" : viewModel.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(viewModel.body.isEmpty ? "Mesaj" : viewModel.body)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
            }
            Spacer()
            Text("şimdi")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(10)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var resultOverlay: some View {
        if let result = viewModel.lastResult {
            Text(result)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.85), in: Capsule())
                .padding(.bottom, -20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if let error = viewModel.error {
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.85), in: Capsule())
                .padding(.bottom, -20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Son Gönderilenler")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .background(.white.opacity(0.03))

            ForEach(viewModel.history) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(log.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(log.sentCount) gönderildi")
                            .font(.system(size: 11))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    Text(log.body)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                    Text(log.sentAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.vertical, 10)

                if log.id != viewModel.history.last?.id {
                    Divider().background(.white.opacity(0.05)).padding(.leading, GrippdTheme.Spacing.md)
                }
            }
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md).stroke(.white.opacity(0.06), lineWidth: 1))
    }
}
