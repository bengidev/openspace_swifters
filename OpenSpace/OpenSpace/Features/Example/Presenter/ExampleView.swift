import ComposableArchitecture
import SwiftUI

struct ExampleView: View {
    let store: StoreOf<ExampleContainer>

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.tint)

                    VStack(spacing: 8) {
                        Text("OpenSpace Example")
                            .font(.title)
                            .fontWeight(.semibold)

                        Text(viewStore.statusMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("example-status-message")
                    }

                    Button("Call NoOp") {
                        viewStore.send(.primaryButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("example-noop-action")
                }
                .padding()
                .navigationTitle("Example")
            }
        })
    }
}

#Preview {
    ExampleView(
        store: Store(initialState: ExampleContainer.State()) {
            ExampleContainer()
        }
    )
}
