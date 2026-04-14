import SwiftUI

// MARK: - ViewModel

@Observable
private final class AdminABTestViewModel {
    var stats: [ExperimentStat] = []
    var isLoading = false
    var error: String?
    var showCreateSheet = false

    func load() async {
        isLoading = true
        error = nil
        do {
            stats = try await AdminABTestService.shared.fetchStats()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleActive(_ stat: ExperimentStat) async {
        do {
            try await AdminABTestService.shared.setActive(stat.id, active: !stat.isActive)
            await load()
            HapticManager.success()
        } catch { HapticManager.error() }
    }

    func delete(_ stat: ExperimentStat) async {
        do {
            try await AdminABTestService.shared.deleteExperiment(stat.id)
            stats.removeAll { $0.id == stat.id }
            HapticManager.success()
        } catch { HapticManager.error() }
    }
}

// MARK: - AdminABTestView

struct AdminABTestView: View {
    @State private var viewModel = AdminABTestViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()
            content
        }
        .navigationTitle("A/B Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateExperimentSheet {
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            GrippdLoadingView(label: "Deneyler yükleniyor...")
        } else if let error = viewModel.error {
            GrippdEmptyStateView(icon: "exclamationmark.triangle", title: "Hata", subtitle: error)
        } else if viewModel.stats.isEmpty {
            GrippdEmptyStateView(
                icon: "arrow.triangle.branch",
                title: "Deney yok",
                subtitle: "Sağ üstten yeni deney oluşturabilirsin"
            )
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    infoCard
                    ForEach(viewModel.stats) { stat in
                        ExperimentCard(stat: stat) {
                            Task { await viewModel.toggleActive(stat) }
                        } onDelete: {
                            Task { await viewModel.delete(stat) }
                        }
                    }
                }
                .padding(GrippdTheme.Spacing.md)
            }
        }
    }

    private var infoCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(.cyan.opacity(0.7))
            Text("Deney aktif edildiğinde yeni kullanıcılar otomatik atanır. Mevcut kullanıcılar etkilenmez.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(GrippdTheme.Spacing.md)
        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
    }
}

// MARK: - ExperimentCard

private struct ExperimentCard: View {
    let stat: ExperimentStat
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(stat.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(stat.totalAssigned) kullanıcı atandı")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.6))
                }
                .buttonStyle(.plain)

                Toggle("", isOn: Binding(
                    get: { stat.isActive },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.switch)
                .tint(.cyan)
                .labelsHidden()
                .scaleEffect(0.85)
            }
            .padding(GrippdTheme.Spacing.md)

            // Varyant dağılımı
            if stat.totalAssigned > 0 {
                Divider().background(.white.opacity(0.06))
                variantBars
                    .padding(GrippdTheme.Spacing.md)
            } else if stat.isActive {
                Divider().background(.white.opacity(0.06))
                Text("Henüz kullanıcı atanmadı")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.vertical, 10)
            }
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(stat.isActive ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .confirmationDialog("Bu deneyi sil?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { onDelete() }
            Button("İptal", role: .cancel) {}
        }
    }

    private var variantBars: some View {
        let total = max(stat.totalAssigned, 1)
        let colors: [Color] = [.cyan, .purple, .orange, .green]
        let sorted = stat.variantCounts.sorted { $0.key < $1.key }

        return VStack(spacing: 8) {
            ForEach(Array(sorted.enumerated()), id: \.element.key) { idx, pair in
                HStack(spacing: 8) {
                    Text(pair.key)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(colors[idx % colors.count])
                        .frame(width: 20)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.06))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colors[idx % colors.count].opacity(0.6))
                                .frame(width: geo.size.width * CGFloat(pair.value) / CGFloat(total))
                        }
                    }
                    .frame(height: 6)

                    Text("\(pair.value)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 36, alignment: .trailing)

                    Text(String(format: "%.0f%%", Double(pair.value) / Double(total) * 100))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - CreateExperimentSheet

private struct CreateExperimentSheet: View {
    let onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var variantCount = 2
    @State private var isSaving = false
    @State private var error: String?

    var experimentKey: String {
        name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Alanlar
                        VStack(spacing: 0) {
                            fieldRow(label: "Deney Adı", placeholder: "Örn: onboarding cta") {
                                TextField("", text: $name)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            Divider().background(.white.opacity(0.06))
                            fieldRow(label: "Açıklama", placeholder: "Ne test ediliyor?") {
                                TextField("", text: $description)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                            }
                            Divider().background(.white.opacity(0.06))
                            fieldRow(label: "Varyant Sayısı", placeholder: "") {
                                Picker("", selection: $variantCount) {
                                    ForEach(2...4, id: \.self) { Text("\($0)") }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                            }
                        }
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))

                        // Kod key önizleme
                        if !name.isEmpty {
                            HStack {
                                Text("Kod anahtarı:")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.4))
                                Text(experimentKey)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.cyan)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }

                        // Varyantlar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Varyantlar")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                            HStack(spacing: 8) {
                                ForEach(0..<variantCount, id: \.self) { i in
                                    let label = String(UnicodeScalar(65 + i)!)
                                    Text(label)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.cyan)
                                        .frame(width: 40, height: 32)
                                        .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                        if let error {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    .padding(GrippdTheme.Spacing.md)
                }
            }
            .navigationTitle("Yeni Deney")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(.white.opacity(0.5))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") { Task { await create() } }
                        .foregroundStyle(canSave ? GrippdTheme.Colors.accent : .white.opacity(0.3))
                        .fontWeight(.semibold)
                        .disabled(!canSave || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func fieldRow<F: View>(label: String, placeholder: String, @ViewBuilder field: () -> F) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 110, alignment: .leading)
            field()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 13)
    }

    private func create() async {
        isSaving = true
        error = nil
        let variants = (0..<variantCount).map { String(UnicodeScalar(65 + $0)!) }
        do {
            try await AdminABTestService.shared.createExperiment(
                name: experimentKey,
                description: description,
                variants: variants
            )
            onCreated()
            dismiss()
            HapticManager.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
        isSaving = false
    }
}
