import SwiftUI

struct FactoryCardChrome<Content: View>: View {
    var cornerRadius: CGFloat = 6
    @ViewBuilder let content: Content

    @Environment(\.palette) private var palette

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
