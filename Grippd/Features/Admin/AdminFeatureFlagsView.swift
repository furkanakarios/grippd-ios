import SwiftUI

// MARK: - ViewModel

@Observable
private final class AdminFeatureFlagsViewModel {
    var flags: [FeatureFlag] = []
    var isLoading = false
    var error: String?
    var showCreateSheet = false

    func load() async {
        isLoading = true
        error = nil
        do {
            flags = try await SupabaseClientService.shared.client
                .from("feature_flags")
                .select()
                .order("created_at")
                .execute()
                .value
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggle(_ flag: FeatureFlag) async {
        guard let idx = flags.firstIndex(where: { $0.id == flag.id }) else { return }
        flags[idx].isEnabled.toggle()
        do {
            struct Patch: Encodable {
                let isEnabled: Bool
                let updatedAt: String
                enum CodingKeys: String, CodingKey {
                    case isEnabled = "is_enabled"
                    case updatedAt = "updated_at"
                }
            }
            try await SupabaseClientService.shared.client
                .from("feature_flags")
                .update(Patch(isEnabled: flags[idx].isEnabled,
                              updatedAt: ISO8601DateFormatter().string(from: Date())))
                .eq("id", value: flag.id.uuidString)
                .execute()
            HapticManager.success()
        } catch {
            flags[idx].isEnabled = flag.isEnabled
            HapticManager.error()
        }
    }

    func delete(_ flag: FeatureFlag) async {
        do {
            try await SupabaseClientService.shared.client
                .from("feature_flags")
                .delete()
                .eq("id", value: flag.id.uuidString)
                .execute()
            flags.removeAll { $0.id == flag.id }
            HapticManager.success()
        } catch { HapticManager.error() }
    }

    func create(key: String, description: String, audience: String) async throws {
        struct Payload: Encodable {
            let key: String
            let description: String
            let audience: String
        }
        try await SupabaseClientService.shared.client
            .from("feature_flags")
            .insert(Payload(key: key, description: description, audience: audience))
            .execute()
        await load()
    }
}

// MARK: - AdminFeatureFlagsView

struct AdminFeatureFlagsView: View {
    @State private var viewModel = AdminFeatureFlagsViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()
            content
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { viewModel.showCreateSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateFlagSheet { key, desc, audience in
                Task {
                    try? await viewModel.create(key: key, description: desc, audience: audience)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            GrippdLoadingView(label: "Flagler yükleniyor...")
        } else if let error = viewModel.error {
            GrippdEmptyStateView(icon: "exclamationmark.triangle", title: "Hata", subtitle: error)
        } else if viewModel.flags.isEmpty {
            GrippdEmptyStateView(icon: "switch.2", title: "Flag yok", subtitle: "Sağ üstten yeni flag ekle")
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(viewModel.flags) { flag in
                        FlagRow(flag: flag) {
                            Task { await viewModel.toggle(flag) }
                        } onDelete: {
                            Task { await viewModel.delete(flag) }
                        }
                        if flag.id != viewModel.flags.last?.id {
                            Divider().background(.white.opacity(0.06))
                                .padding(.leading, GrippdTheme.Spacing.md)
                        }
                    }
                }
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                .padding(GrippdTheme.Spacing.md)

                usageHint
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
    }

    private var usageHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kod içinde kullanım")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
            Text("FeatureFlagService.shared.isEnabled(\"key\")")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.6))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - FlagRow

private struct FlagRow: View {
    let flag: FeatureFlag
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var audienceColor: Color {
        switch flag.audience {
        case "premium": return .yellow
        case "admin":   return .red
        default:        return .mint
        }
    }

    var audienceLabel: String {
        switch flag.audience {
        case "premium": return "Premium"
        case "admin":   return "Admin"
        default:        return "Herkes"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Durum göstergesi
            Circle()
                .fill(flag.isEnabled ? Color.mint : Color.white.opacity(0.15))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(flag.key)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(audienceLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(audienceColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(audienceColor.opacity(0.12), in: Capsule())
                }
                if !flag.description.isEmpty {
                    Text(flag.description)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button { showDeleteConfirm = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.red.opacity(0.5))
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { flag.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .tint(.mint)
            .labelsHidden()
            .scaleEffect(0.85)
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
        .confirmationDialog("'\(flag.key)' flagini sil?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { onDelete() }
            Button("İptal", role: .cancel) {}
        }
    }
}

// MARK: - CreateFlagSheet

private struct CreateFlagSheet: View {
    let onCreate: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var description = ""
    @State private var audience = "all"

    var flagKey: String {
        key.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var canCreate: Bool { !key.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        fieldRow(label: "Key") {
                            TextField("Örn: new_feed_algorithm", text: $key)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        Divider().background(.white.opacity(0.06))
                        fieldRow(label: "Açıklama") {
                            TextField("Ne işe yarıyor?", text: $description)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                        }
                        Divider().background(.white.opacity(0.06))
                        fieldRow(label: "Kitle") {
                            Picker("", selection: $audience) {
                                Text("Herkes").tag("all")
                                Text("Premium").tag("premium")
                                Text("Admin").tag("admin")
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 180)
                        }
                    }
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))

                    if !key.isEmpty {
                        HStack {
                            Text("Flag key:")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                            Text(flagKey)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.mint)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }

                    Spacer()
                }
                .padding(GrippdTheme.Spacing.md)
            }
            .navigationTitle("Yeni Flag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(.white.opacity(0.5))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ekle") {
                        onCreate(flagKey, description, audience)
                        dismiss()
                        HapticManager.success()
                    }
                    .foregroundStyle(canCreate ? GrippdTheme.Colors.accent : .white.opacity(0.3))
                    .fontWeight(.semibold)
                    .disabled(!canCreate)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func fieldRow<F: View>(label: String, @ViewBuilder field: () -> F) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 70, alignment: .leading)
            field()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 13)
    }
}
