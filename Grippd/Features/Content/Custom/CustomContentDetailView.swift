import SwiftUI

struct CustomContentDetailView: View {
    let contentID: UUID

    @State private var item: UserCreatedContent?
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GrippdBackground()

            if let item {
                contentView(item: item)
            } else {
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("İçerik bulunamadı")
                        .font(GrippdTheme.Typography.title)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(item?.title ?? "İçerik")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Düzenle") { showEdit = true }
                    Button("Sil", role: .destructive) { showDeleteConfirm = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let item {
                EditCustomContentView(item: item) { loadItem() }
            }
        }
        .confirmationDialog("İçeriği sil?", isPresented: $showDeleteConfirm) {
            Button("Sil", role: .destructive) { deleteItem() }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu içerik kalıcı olarak silinecek.")
        }
        .task { loadItem() }
    }

    private func contentView(item: UserCreatedContent) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero
                heroSection(item: item)

                // Info
                VStack(alignment: .leading, spacing: GrippdTheme.Spacing.lg) {
                    // Kullanıcı ekledi badge
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                        Text("Senin eklediğin içerik")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(GrippdTheme.Colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GrippdTheme.Colors.accent.opacity(0.12), in: Capsule())
                    .padding(.horizontal, GrippdTheme.Spacing.md)

                    // Genres
                    if !item.genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(item.genres, id: \.self) { genre in
                                    Text(genre)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(GrippdTheme.Colors.accent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(GrippdTheme.Colors.accent.opacity(0.1), in: Capsule())
                                        .overlay(Capsule().stroke(GrippdTheme.Colors.accent.opacity(0.35), lineWidth: 1))
                                }
                            }
                            .padding(.horizontal, GrippdTheme.Spacing.md)
                        }
                    }

                    // Overview
                    if let overview = item.overview, !overview.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Özet")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.45))
                                .textCase(.uppercase)
                                .tracking(1.2)
                            Text(overview)
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineSpacing(5)
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.md)
                    }

                    // Meta
                    VStack(spacing: 0) {
                        if let year = item.year {
                            metaRow(label: "Yıl", value: "\(year)")
                        }
                        if let runtime = item.runtime {
                            let label = item.contentType == .book ? "Sayfa Sayısı" : "Süre"
                            let value = item.contentType == .book ? "\(runtime) sayfa" : "\(runtime) dk"
                            metaRow(label: label, value: value)
                        }
                        metaRow(label: "Eklenme Tarihi", value: item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                }
                .padding(.top, GrippdTheme.Spacing.lg)
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
    }

    private func heroSection(item: UserCreatedContent) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Arka plan
            Rectangle()
                .fill(GrippdTheme.Colors.surface)
                .frame(height: 160)

            // Poster
            HStack(alignment: .bottom, spacing: GrippdTheme.Spacing.md) {
                AsyncImage(url: item.posterURLString.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                            .fill(GrippdTheme.Colors.background)
                            .overlay(
                                Image(systemName: typeIcon(item.contentType))
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.2))
                            )
                    }
                }
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
                .padding(.leading, GrippdTheme.Spacing.md)
                .padding(.bottom, -40)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        Text(typeLabel(item.contentType))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.55))

                        if let year = item.year {
                            Text("· \(year)")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
                .padding(.bottom, GrippdTheme.Spacing.sm)

                Spacer()
            }
        }
        .frame(height: 160)
        .padding(.bottom, 40)
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.vertical, 12)
        .overlay(Divider().background(.white.opacity(0.07)), alignment: .bottom)
    }

    @MainActor
    private func loadItem() {
        item = UserContentService.shared.find(id: contentID.uuidString)
    }

    @MainActor
    private func deleteItem() {
        if let item { UserContentService.shared.delete(item) }
        dismiss()
    }

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

// MARK: - Edit View

struct EditCustomContentView: View {
    let item: UserCreatedContent
    var onSaved: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var yearText: String
    @State private var overview: String
    @State private var posterURLText: String
    @State private var genresText: String
    @State private var runtimeText: String

    init(item: UserCreatedContent, onSaved: (() -> Void)? = nil) {
        self.item = item
        self.onSaved = onSaved
        _title = State(initialValue: item.title)
        _yearText = State(initialValue: item.year.map { "\($0)" } ?? "")
        _overview = State(initialValue: item.overview ?? "")
        _posterURLText = State(initialValue: item.posterURLString ?? "")
        _genresText = State(initialValue: item.genres.joined(separator: ", "))
        _runtimeText = State(initialValue: item.runtime.map { "\($0)" } ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                ScrollView {
                    VStack(spacing: 1) {
                        editField(label: "Başlık", text: $title)
                        editField(label: "Yıl", text: $yearText, keyboard: .numberPad)
                        editField(label: "Süre/Sayfa", text: $runtimeText, keyboard: .numberPad)
                        editField(label: "Türler", text: $genresText)
                        editField(label: "Kapak URL", text: $posterURLText, keyboard: .URL)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.md)

                    // Overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Özet")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.55))
                        TextEditor(text: $overview)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .tint(GrippdTheme.Colors.accent)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(GrippdTheme.Spacing.sm)
                            .background(GrippdTheme.Colors.surface, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.md)
                }
            }
            .navigationTitle("Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }.foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") { saveChanges() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func editField(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 100, alignment: .leading)
            TextField("", text: text)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .tint(GrippdTheme.Colors.accent)
                .keyboardType(keyboard)
                .autocorrectionDisabled(keyboard != .default)
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 14)
        .background(GrippdTheme.Colors.surface)
        .overlay(Divider().background(.white.opacity(0.06)), alignment: .bottom)
    }

    @MainActor
    private func saveChanges() {
        item.title = title.trimmingCharacters(in: .whitespaces)
        item.year = Int(yearText)
        item.overview = overview.isEmpty ? nil : overview.trimmingCharacters(in: .whitespaces)
        item.posterURLString = posterURLText.isEmpty ? nil : posterURLText.trimmingCharacters(in: .whitespaces)
        item.genresRaw = genresText
        item.runtime = Int(runtimeText)
        UserContentService.shared.update(item)
        onSaved?()
        dismiss()
    }
}
