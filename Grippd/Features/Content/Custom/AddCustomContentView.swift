import SwiftUI

struct AddCustomContentView: View {
    @Environment(\.dismiss) private var dismiss

    // Form alanları
    @State private var title = ""
    @State private var contentType: Content.ContentType = .movie
    @State private var yearText = ""
    @State private var overview = ""
    @State private var posterURLText = ""
    @State private var genresText = ""
    @State private var runtimeText = ""

    @State private var showValidationError = false
    var onSaved: (() -> Void)?

    private var runtimeLabel: String {
        contentType == .book ? "Sayfa Sayısı" : "Süre (dakika)"
    }

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()

                ScrollView {
                    VStack(spacing: GrippdTheme.Spacing.lg) {
                        // Tür seçici
                        typeSelector
                            .padding(.top, GrippdTheme.Spacing.md)

                        // Form alanları
                        VStack(spacing: 1) {
                            formField(label: "Başlık *", placeholder: "İçerik adı", text: $title)
                            formField(label: "Yıl", placeholder: "2024", text: $yearText, keyboard: .numberPad)
                            formField(label: runtimeLabel, placeholder: contentType == .book ? "320" : "120", text: $runtimeText, keyboard: .numberPad)
                            formField(label: "Türler", placeholder: "Dram, Komedi, Gerilim", text: $genresText)
                            formField(label: "Kapak URL", placeholder: "https://...", text: $posterURLText, keyboard: .URL)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                        .padding(.horizontal, GrippdTheme.Spacing.md)

                        // Özet
                        overviewField
                            .padding(.horizontal, GrippdTheme.Spacing.md)

                        if showValidationError {
                            Text("Başlık alanı zorunludur.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.red.opacity(0.8))
                                .padding(.horizontal, GrippdTheme.Spacing.md)
                        }
                    }
                    .padding(.bottom, GrippdTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Yeni İçerik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") { saveContent() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isValid ? GrippdTheme.Colors.accent : .white.opacity(0.3))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach([Content.ContentType.movie, .tv_show, .book], id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { contentType = type }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: typeIcon(type))
                            .font(.system(size: 20))
                        Text(typeLabel(type))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(contentType == type ? GrippdTheme.Colors.background : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        contentType == type ? GrippdTheme.Colors.accent : Color.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                    )
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Form Field

    private func formField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 120, alignment: .leading)

            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .tint(GrippdTheme.Colors.accent)
                .keyboardType(keyboard)
                .autocorrectionDisabled(keyboard != .default)
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 14)
        .background(GrippdTheme.Colors.surface)
        .overlay(
            Divider().background(.white.opacity(0.06)),
            alignment: .bottom
        )
    }

    // MARK: - Overview Field

    private var overviewField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Özet")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))

            ZStack(alignment: .topLeading) {
                if overview.isEmpty {
                    Text("Kısa bir açıklama ekle (isteğe bağlı)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.2))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $overview)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .tint(GrippdTheme.Colors.accent)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
            }
            .padding(GrippdTheme.Spacing.sm)
            .background(GrippdTheme.Colors.surface, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        }
    }

    // MARK: - Save

    private func saveContent() {
        guard isValid else {
            withAnimation { showValidationError = true }
            return
        }

        let genres = genresText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let item = UserCreatedContent(
            title: title.trimmingCharacters(in: .whitespaces),
            contentType: contentType,
            year: Int(yearText),
            overview: overview.isEmpty ? nil : overview.trimmingCharacters(in: .whitespaces),
            posterURLString: posterURLText.isEmpty ? nil : posterURLText.trimmingCharacters(in: .whitespaces),
            genres: genres,
            runtime: Int(runtimeText)
        )

        Task { @MainActor in
            UserContentService.shared.save(item)
            onSaved?()
            dismiss()
        }
    }

    // MARK: - Helpers

    private func typeLabel(_ type: Content.ContentType) -> String {
        switch type {
        case .movie: return "Film"
        case .tv_show: return "Dizi"
        case .book: return "Kitap"
        }
    }

    private func typeIcon(_ type: Content.ContentType) -> String {
        switch type {
        case .movie: return "film"
        case .tv_show: return "tv"
        case .book: return "book.closed"
        }
    }
}
