import Foundation
import SwiftUI
import PhotosUI

@Observable
final class OnboardingViewModel {

    // MARK: - Step
    enum Step { case username, interests, avatar }
    var currentStep: Step = .username

    // MARK: - Fields
    var username = ""
    var displayName = ""
    var selectedInterests: Set<ContentInterest> = []
    var avatarItem: PhotosPickerItem?
    var avatarImage: Image?
    var avatarData: Data?

    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    var isCheckingUsername = false
    var isUsernameAvailable: Bool? = nil

    private let service = OnboardingService.shared
    private var usernameCheckTask: Task<Void, Never>?

    // MARK: - Username Check (debounced)

    func onUsernameChange() {
        usernameCheckTask?.cancel()
        isUsernameAvailable = nil

        let trimmed = username.trimmingCharacters(in: .whitespaces).lowercased()
        guard trimmed.count >= 3 else { return }

        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            await MainActor.run { isCheckingUsername = true }
            let available = (try? await service.isUsernameAvailable(trimmed)) ?? false
            await MainActor.run {
                isUsernameAvailable = available
                isCheckingUsername = false
            }
        }
    }

    // MARK: - Avatar Load

    func loadAvatar() async {
        guard let item = avatarItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data),
              let compressed = uiImage.jpegData(compressionQuality: 0.7) else { return }

        await MainActor.run {
            avatarData = compressed
            avatarImage = Image(uiImage: uiImage)
        }
    }

    // MARK: - Navigation

    var canProceedFromUsername: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 3 && isUsernameAvailable == true
    }

    func nextStep() {
        switch currentStep {
        case .username: currentStep = .interests
        case .interests: currentStep = .avatar
        case .avatar: break
        }
    }

    func previousStep() {
        switch currentStep {
        case .username: break
        case .interests: currentStep = .username
        case .avatar: currentStep = .interests
        }
    }

    // MARK: - Complete

    func complete(appState: AppState) async {
        guard let userID = await MainActor.run(body: { appState.currentUser?.id }) else { return }

        isLoading = true
        errorMessage = nil

        do {
            let updatedUser = try await service.completeOnboarding(
                userID: userID,
                username: username.trimmingCharacters(in: .whitespaces).lowercased(),
                displayName: displayName,
                interests: Array(selectedInterests),
                avatarData: avatarData
            )
            await MainActor.run {
                appState.currentUser = updatedUser
                appState.needsOnboarding = false
                isLoading = false
                LogService.shared.setOwner(updatedUser.id.uuidString)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
