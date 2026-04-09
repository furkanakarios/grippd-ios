import SwiftUI

struct SearchFilterSheet: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var localFilters: SearchFilters

    private let currentYear = Calendar.current.component(.year, from: Date())
    private let years: [Int]

    init(filters: Binding<SearchFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._localFilters = State(initialValue: filters.wrappedValue)
        let year = Calendar.current.component(.year, from: Date())
        self.years = Array(stride(from: year, through: 1900, by: -1))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Yıl Aralığı
                        filterSection(title: "Yıl Aralığı", icon: "calendar") {
                            HStack(spacing: 12) {
                                yearPicker(label: "Başlangıç", value: $localFilters.minYear, maxYear: localFilters.maxYear)
                                Text("–").foregroundStyle(.white.opacity(0.4))
                                yearPicker(label: "Bitiş", value: $localFilters.maxYear, minYear: localFilters.minYear)
                            }
                        }

                        // Minimum Puan
                        filterSection(title: "Minimum Puan", icon: "star.fill") {
                            VStack(spacing: 8) {
                                HStack {
                                    Text(localFilters.minRating.map { String(format: "%.1f", $0) } ?? "Tümü")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(GrippdTheme.Colors.accent)
                                    Spacer()
                                    if localFilters.minRating != nil {
                                        Button("Temizle") { localFilters.minRating = nil }
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                }
                                Slider(
                                    value: Binding(
                                        get: { localFilters.minRating ?? 0 },
                                        set: { localFilters.minRating = $0 > 0 ? $0 : nil }
                                    ),
                                    in: 0...9, step: 0.5
                                )
                                .tint(GrippdTheme.Colors.accent)
                                HStack {
                                    Text("0").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                                    Spacer()
                                    Text("9+").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.md)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sıfırla") {
                        localFilters.reset()
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .disabled(!localFilters.isActive)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") {
                        filters = localFilters
                        onApply()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func filterSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GrippdTheme.Colors.accent)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            content()
        }
        .padding(16)
        .background(GrippdTheme.Colors.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }

    private func yearPicker(label: String, value: Binding<Int?>, minYear: Int? = nil, maxYear: Int? = nil) -> some View {
        let availableYears = years.prefix(50).filter { year in
            if let min = minYear, year < min { return false }
            if let max = maxYear, year > max { return false }
            return true
        }
        return Menu {
            Button("Tümü") { value.wrappedValue = nil }
            ForEach(availableYears, id: \.self) { year in
                Button(String(year)) { value.wrappedValue = year }
            }
        } label: {
            HStack(spacing: 4) {
                Text(value.wrappedValue.map { String($0) } ?? label)
                    .font(.system(size: 14))
                    .foregroundStyle(value.wrappedValue != nil ? .white : .white.opacity(0.4))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
