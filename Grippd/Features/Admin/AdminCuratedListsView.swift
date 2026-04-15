import SwiftUI

private extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str.removeFirst() }
        guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    }
}

// MARK: - ViewModel

@Observable
private final class AdminCuratedListsViewModel {
    var rows: [CuratedCollectionRow] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            rows = try await AdminCuratedListsService.shared.fetchAll()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleActive(_ row: CuratedCollectionRow) async {
        guard let idx = rows.firstIndex(where: { $0.id == row.id }) else { return }
        rows[idx].isActive.toggle()
        do {
            try await AdminCuratedListsService.shared.setActive(row.id, active: rows[idx].isActive)
            HapticManager.success()
        } catch {
            rows[idx].isActive = row.isActive
            HapticManager.error()
        }
    }

    func save(_ updated: CuratedCollectionRow) async {
        guard let idx = rows.firstIndex(where: { $0.id == updated.id }) else { return }
        rows[idx] = updated
        do {
            try await AdminCuratedListsService.shared.update(updated)
            HapticManager.success()
        } catch {
            HapticManager.error()
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        rows.move(fromOffsets: source, toOffset: destination)
        Task { try? await AdminCuratedListsService.shared.moveSortOrder(rows: rows) }
    }
}

// MARK: - AdminCuratedListsView

struct AdminCuratedListsView: View {
    @State private var viewModel = AdminCuratedListsViewModel()
    @State private var editingRow: CuratedCollectionRow?

    var body: some View {
        ZStack {
            GrippdBackground()
            content
        }
        .navigationTitle("Küratör Listeler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .sheet(item: $editingRow) { row in
            CuratedListEditSheet(row: row) { updated in
                Task { await viewModel.save(updated) }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            GrippdLoadingView(label: "Listeler yükleniyor...")
        } else if let error = viewModel.error {
            GrippdEmptyStateView(icon: "exclamationmark.triangle", title: "Hata", subtitle: error)
        } else {
            List {
                Section {
                    ForEach(viewModel.rows) { row in
                        CuratedRowItem(row: row) {
                            editingRow = row
                        } onToggle: {
                            Task { await viewModel.toggleActive(row) }
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                        .listRowSeparatorTint(.white.opacity(0.07))
                    }
                    .onMove { source, destination in
                        viewModel.move(from: source, to: destination)
                    }
                } header: {
                    Text("Sürükle ile sıralamayı değiştir")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                        .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
    }
}

// MARK: - CuratedRowItem

private struct CuratedRowItem: View {
    let row: CuratedCollectionRow
    let onEdit: () -> Void
    let onToggle: () -> Void

    var accentColor: Color {
        Color(hex: row.accentHex) ?? GrippdTheme.Colors.accent
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.opacity(row.isActive ? 0.2 : 0.07))
                    .frame(width: 36, height: 36)
                Image(systemName: row.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(accentColor.opacity(row.isActive ? 1 : 0.3))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(row.isActive ? .white : .white.opacity(0.3))
                Text(row.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(row.isActive ? 0.45 : 0.2))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { row.isActive },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .tint(accentColor)
            .labelsHidden()
            .scaleEffect(0.85)
        }
        .padding(.vertical, 4)
        .opacity(row.isActive ? 1 : 0.6)
    }
}

// MARK: - CuratedListEditSheet

private struct CuratedListEditSheet: View {
    @State var row: CuratedCollectionRow
    let onSave: (CuratedCollectionRow) -> Void

    @Environment(\.dismiss) private var dismiss

    var accentColor: Color {
        Color(hex: row.accentHex) ?? GrippdTheme.Colors.accent
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Önizleme
                        previewCard

                        // Alanlar
                        VStack(spacing: 0) {
                            editField(label: "Başlık", text: $row.title)
                            Divider().background(.white.opacity(0.06)).padding(.leading, GrippdTheme.Spacing.md)
                            editField(label: "Alt başlık", text: $row.subtitle)
                            Divider().background(.white.opacity(0.06)).padding(.leading, GrippdTheme.Spacing.md)
                            editField(label: "SF Symbol", text: $row.icon)
                            Divider().background(.white.opacity(0.06)).padding(.leading, GrippdTheme.Spacing.md)
                            editField(label: "Renk (hex)", text: $row.accentHex)
                        }
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))

                        Text("SF Symbol adı için Apple'ın SF Symbols uygulamasından kopyalayabilirsin.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    .padding(GrippdTheme.Spacing.md)
                }
            }
            .navigationTitle("Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(.white.opacity(0.5))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave(row)
                        dismiss()
                    }
                    .foregroundStyle(GrippdTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: row.icon.isEmpty ? "questionmark" : row.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title.isEmpty ? "Başlık" : row.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(row.subtitle.isEmpty ? "Alt başlık" : row.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(GrippdTheme.Spacing.md)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func editField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 90, alignment: .leading)
            TextField("", text: text)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 13)
    }
}
