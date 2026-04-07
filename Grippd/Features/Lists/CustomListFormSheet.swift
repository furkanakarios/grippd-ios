import SwiftUI

struct CustomListFormSheet: View {
    @Binding var isPresented: Bool
    var existingList: CustomList? = nil
    var onSaved: ((CustomList) -> Void)? = nil

    @State private var name: String = ""
    @State private var selectedEmoji: String = "📋"
    @State private var showEmojiPicker = false
    @State private var customEmojiInput = ""

    private let suggestedEmojis = ["📋","🎬","📺","📚","⭐","🔥","💎","🎭","🎪","🌟","💫","🎯","🎨","🏆","❤️","😍","🤩","🎞","📽","🎥"]

    private var isEditing: Bool { existingList != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.13).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Emoji seçici
                        emojiSection

                        // Liste adı
                        nameSection

                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(isEditing ? "Listeyi Düzenle" : "Yeni Liste")
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
        .onAppear {
            if let list = existingList {
                name = list.name
                selectedEmoji = list.emoji
            }
        }
    }

    // MARK: - Emoji Section

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("İkon")

            // Büyük emoji gösterge
            HStack {
                Spacer()
                Text(selectedEmoji)
                    .font(.system(size: 64))
                    .frame(width: 100, height: 100)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
                Spacer()
            }

            // Öneri emojileri
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(suggestedEmojis, id: \.self) { emoji in
                    Button {
                        withAnimation(.spring(response: 0.2)) { selectedEmoji = emoji }
                    } label: {
                        Text(emoji)
                            .font(.system(size: 26))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                selectedEmoji == emoji
                                    ? GrippdTheme.Colors.accent.opacity(0.2)
                                    : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedEmoji == emoji ? GrippdTheme.Colors.accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Liste Adı")

            TextField("Örn: 2024 Favorileri", text: $name)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(GrippdTheme.Colors.accent)
                .padding(14)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: save) {
            Text(isEditing ? "Kaydet" : "Liste Oluştur")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(canSave ? GrippdTheme.Colors.background : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    canSave ? GrippdTheme.Colors.accent : Color.white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .disabled(!canSave)
        .padding(.top, 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(1.0)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let list: CustomList
        if let existing = existingList {
            CustomListService.shared.updateList(existing, name: trimmed, emoji: selectedEmoji)
            list = existing
        } else {
            list = CustomListService.shared.createList(name: trimmed, emoji: selectedEmoji)
        }
        onSaved?(list)
        isPresented = false
    }
}
