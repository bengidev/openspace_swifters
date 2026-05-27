import ComposableArchitecture
import SwiftUI

struct OnboardingBottomNavigationView: View {
    let store: StoreOf<OnboardingFlow>

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(0..<store.totalPages, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            _ = store.send(.pageSelected(index))
                        }
                    } label: {
                        Capsule(style: .continuous)
                            .fill(index == store.currentPage ? palette.accent : palette.border)
                            .frame(width: index == store.currentPage ? 28 : 6, height: 6)
                            .animation(.spring(response: 0.34, dampingFraction: 0.76), value: store.currentPage)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Go to onboarding page \(index + 1)")
                }
            }

            HStack(spacing: 10) {
                if store.currentPage > 0 {
                    Button {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            _ = store.send(.previousTapped)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                            Text("BACK")
                        }
                    }
                    .buttonStyle(FactorySecondaryButtonStyle(palette: palette))
                    .accessibilityLabel("Previous onboarding page")
                }

                Button {
                    if store.isLastPage {
                        _ = store.send(.finishTapped)
                    } else {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            _ = store.send(.nextTapped)
                        }
                    }
                } label: {
                    HStack(spacing: 9) {
                        Text(store.isLastPage ? "ENTER OPENSPACE" : "CONTINUE")
                        Image(systemName: store.isLastPage ? "arrow.up.right" : "arrow.right")
                    }
                }
                .buttonStyle(FactoryPrimaryButtonStyle(palette: palette))
                .accessibilityLabel(store.isLastPage ? "Enter OpenSpace" : "Continue onboarding")
            }
        }
    }
}
