import SwiftUI

// MARK: - LogEntrySheet

struct LogEntrySheet: View {
    let contentKey: String
    let contentType: Content.ContentType
    let contentTitle: String
    let posterPath: String?
    @Binding var isPresented: Bool
    var defaultIsRewatch: Bool = false
    var onSaved: (() -> Void)?

    @State private var watchedAt: Date = Date()
    @State private var selectedPlatform: LogPlatform?
    @State private var isRewatch: Bool
    @State private var rating: Double? = nil
    @State private var selectedEmoji: String? = nil
    @State private var customEmoji: String = ""
    @State private var showCustomEmojiInput: Bool = false
    @State private var note: String = ""

    init(
        contentKey: String,
        contentType: Content.ContentType,
        contentTitle: String,
        posterPath: String?,
        isPresented: Binding<Bool>,
        defaultIsRewatch: Bool = false,
        onSaved: (() -> Void)? = nil
    ) {
        self.contentKey = contentKey
        self.contentType = contentType
        self.contentTitle = contentTitle
        self.posterPath = posterPath
        self._isPresented = isPresented
        self.defaultIsRewatch = defaultIsRewatch
        self.onSaved = onSaved
        self._isRewatch = State(initialValue: defaultIsRewatch)
    }

    private var presetEmojis: [String] {
        switch contentType {
        case .movie, .tv_show:
            return ["🤩","😍","😭","😂","😱","🔥","💀","🥱","🤔","💔","👌","🎬"]
        case .book:
            return ["🤩","😍","😭","😂","🤯","💡","🔥","❤️","📚","👌","🤔","😴"]
        }
    }

    private var availablePlatforms: [LogPlatform] {
        LogPlatform.platforms(for: contentType)
    }

    private var actionLabel: String {
        contentType == .book ? "Okudum" : "İzledim"
    }

    private var rewatchLabel: String {
        contentType == .book ? "Tekrar Okuma" : "Tekrar İzleme"
    }

    private var rewatchSubtitle: String {
        contentType == .book ? "Bu kitabı daha önce okudun" : "Bu içeriği daha önce izledin"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.13).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        dateSection
                        platformSection
                        ratingSection
                        emojiSection
                        rewatchSection
                        noteSection
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(actionLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .toolbarBackground(Color(red: 0.10, green: 0.10, blue: 0.13), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Ne Zaman?")

            DatePicker(
                "",
                selection: $watchedAt,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(GrippdTheme.Colors.accent)
            .padding(12)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            .labelsHidden()
        }
    }

    // MARK: - Platform Section

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Nereden?")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availablePlatforms) { platform in
                        PlatformChip(platform: platform, isSelected: selectedPlatform == platform) {
                            withAnimation(.spring(response: 0.25)) {
                                selectedPlatform = (selectedPlatform == platform) ? nil : platform
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Puanın (İsteğe Bağlı)")

            StarRatingView(rating: $rating, starSize: 38, spacing: 8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Emoji Section

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Reaksiyon (İsteğe Bağlı)")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Preset emojiler
                    ForEach(presetEmojis, id: \.self) { emoji in
                        EmojiChip(
                            emoji: emoji,
                            isSelected: selectedEmoji == emoji
                        ) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                if selectedEmoji == emoji {
                                    selectedEmoji = nil
                                } else {
                                    selectedEmoji = emoji
                                    customEmoji = ""
                                    showCustomEmojiInput = false
                                }
                            }
                        }
                    }

                    // Serbest emoji butonu
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            showCustomEmojiInput.toggle()
                            if !showCustomEmojiInput { customEmoji = "" }
                        }
                    } label: {
                        Text(showCustomEmojiInput ? "✕" : "+")
                            .font(.system(size: showCustomEmojiInput ? 14 : 20, weight: .medium))
                            .frame(width: 48, height: 48)
                            .background(
                                showCustomEmojiInput
                                    ? Color.white.opacity(0.15)
                                    : Color.white.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }

            // Serbest emoji input
            if showCustomEmojiInput {
                HStack(spacing: 10) {
                    TextField("Emoji gir...", text: $customEmoji)
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .multilineTextAlignment(.center)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        .onChange(of: customEmoji) { _, new in
                            // Sadece ilk karakteri (emoji) al
                            let emojis = new.filter { $0.isEmoji }
                            if let first = emojis.first {
                                customEmoji = String(first)
                            } else {
                                customEmoji = ""
                            }
                        }

                    if !customEmoji.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                selectedEmoji = customEmoji
                                showCustomEmojiInput = false
                            }
                        } label: {
                            Text("Seç")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(GrippdTheme.Colors.background)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Seçili emoji önizleme
            if let emoji = selectedEmoji {
                HStack(spacing: 8) {
                    Text(emoji)
                        .font(.system(size: 22))
                    Text("Reaksiyonun seçildi")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            selectedEmoji = nil
                            customEmoji = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
    }

    // MARK: - Rewatch Section

    private var rewatchSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(rewatchLabel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(rewatchSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: $isRewatch)
                .tint(GrippdTheme.Colors.accent)
                .labelsHidden()
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Not (İsteğe Bağlı)")

            TextField("Düşüncelerini yaz...", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .tint(GrippdTheme.Colors.accent)
                .padding(14)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: save) {
            Text("Kaydet")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(GrippdTheme.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.press)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(1.0)
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = LogEntry(
            ownerID: LogService.shared.currentOwnerID,
            contentKey: contentKey,
            contentType: contentType,
            contentTitle: contentTitle,
            posterPath: posterPath,
            watchedAt: watchedAt,
            platform: selectedPlatform,
            isRewatch: isRewatch,
            rating: rating,
            emoji: selectedEmoji,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        LogService.shared.save(entry)
        HapticManager.success()
        onSaved?()
        isPresented = false
    }
}

// MARK: - Emoji Chip

private struct EmojiChip: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 48, height: 48)
                .background(
                    isSelected
                        ? GrippdTheme.Colors.accent.opacity(0.2)
                        : Color.white.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? GrippdTheme.Colors.accent.opacity(0.7) : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .scaleEffect(isSelected ? 1.08 : 1.0)
        }
    }
}

// MARK: - Platform Chip

private struct PlatformChip: View {
    let platform: LogPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.system(size: 13))
                Text(platform.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? GrippdTheme.Colors.background : .white.opacity(0.75))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected ? GrippdTheme.Colors.accent : Color.white.opacity(0.08),
                in: Capsule()
            )
        }
    }
}
