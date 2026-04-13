import SwiftUI

struct AddToListSheet: View {
    let contentKey: String
    let contentType: Content.ContentType
    let contentTitle: String
    let posterPath: String?
    @Binding var isPresented: Bool

    @Environment(AppState.self) private var appState
    @State private var lists: [CustomList] = []
    @State private var showCreateSheet = false
    @State private var showPaywall = false

    private static let freeListLimit = 3

    private func tryCreateList() {
        if !appState.isPremium && lists.count >= Self.freeListLimit {
            showPaywall = true
        } else {
            showCreateSheet = true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.13).ignoresSafeArea()

                if lists.isEmpty {
                    VStack(spacing: GrippdTheme.Spacing.md) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 44))
                            .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.3))
                        Text("Henüz liste yok")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        createButton
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(lists) { list in
                                let inList = CustomListService.shared.isInList(list, contentKey: contentKey)
                                Button {
                                    if inList {
                                        CustomListService.shared.removeItem(from: list, contentKey: contentKey)
                                    } else {
                                        CustomListService.shared.addItem(
                                            to: list,
                                            contentKey: contentKey,
                                            contentType: contentType,
                                            title: contentTitle,
                                            posterPath: posterPath
                                        )
                                    }
                                    lists = CustomListService.shared.allLists()
                                } label: {
                                    HStack(spacing: 14) {
                                        Text(list.emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(list.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("\(list.items.count) içerik")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white.opacity(0.4))
                                        }

                                        Spacer()

                                        Image(systemName: inList ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22))
                                            .foregroundStyle(inList ? GrippdTheme.Colors.accent : .white.opacity(0.25))
                                    }
                                    .padding(.horizontal, GrippdTheme.Spacing.md)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Divider().background(.white.opacity(0.06)).padding(.leading, 72)
                            }

                            createButton
                                .padding(.horizontal, GrippdTheme.Spacing.md)
                                .padding(.top, GrippdTheme.Spacing.md)
                        }
                        .padding(.top, GrippdTheme.Spacing.sm)
                    }
                }
            }
            .navigationTitle("Listeye Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .toolbarBackground(Color(red: 0.10, green: 0.10, blue: 0.13), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .onAppear { lists = CustomListService.shared.allLists() }
        .sheet(isPresented: $showCreateSheet) {
            CustomListFormSheet(isPresented: $showCreateSheet) { _ in
                lists = CustomListService.shared.allLists()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView()
        }
    }

    private var createButton: some View {
        Button {
            tryCreateList()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(GrippdTheme.Colors.accent)
                Text("Yeni Liste Oluştur")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GrippdTheme.Colors.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(GrippdTheme.Colors.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
