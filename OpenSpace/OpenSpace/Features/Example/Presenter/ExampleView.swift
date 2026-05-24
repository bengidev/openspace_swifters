import SwiftUI

struct ExampleView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("OpenSpace Example")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("A minimal feature shell ready for reducers and clients.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Example")
        }
    }
}

#Preview {
    ExampleView()
}
