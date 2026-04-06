import SwiftUI

// MARK: - LogEntrySheet

struct LogEntrySheet: View {
    let contentKey: String
    let contentType: Content.ContentType
    let contentTitle: String
    let posterPath: String?
    @Binding var isPresented: Bool
    var onSaved: (() -> Void)?

    @State private var watchedAt: Date = Date()
    @State private var selectedPlatform: LogPlatform?
    @State private var isRewatch: Bool = false
    @State private var rating: Double? = nil
    @State private var note: String = ""

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
            contentKey: contentKey,
            contentType: contentType,
            contentTitle: contentTitle,
            posterPath: posterPath,
            watchedAt: watchedAt,
            platform: selectedPlatform,
            isRewatch: isRewatch,
            rating: rating,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        LogService.shared.save(entry)
        onSaved?()
        isPresented = false
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
