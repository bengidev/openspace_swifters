import ComposableArchitecture
import SwiftUI

enum OnboardingPageVisualFactory {
    @ViewBuilder
    static func make(
        page: OnboardingPageModel,
        store: StoreOf<OnboardingPageDemo>,
        appeared: Bool
    ) -> some View {
        switch page.type {
        case .encryptedPairing:
            OnboardingEncryptedPairingVisualView(
                isConfirmed: store.pairingConfirmed,
                appeared: appeared,
                onToggle: { store.send(.pairingToggleTapped) }
            )

        case .ideaStudio:
            OnboardingIdeaStudioVisualView(
                selectedPromptIndex: store.selectedPromptIndex,
                appeared: appeared,
                onPromptSelected: { store.send(.promptChipTapped($0)) }
            )

        case .promptQueue:
            OnboardingPromptQueueVisualView(
                queuedPromptCount: store.queuedPromptCount,
                appeared: appeared
            )

        case .reasoningControl:
            OnboardingReasoningControlVisualView(
                reasoningLevel: Binding(
                    get: { store.reasoningLevel },
                    set: { store.send(.reasoningLevelChanged($0)) }
                ),
                appeared: appeared
            )

        case .workspaceReady:
            OnboardingWorkspaceReadyVisualView(
                page: page,
                appeared: appeared
            )
        }
    }
}
