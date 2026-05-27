import SwiftUI

struct FactoryBadge: View {
    let title: String
    var systemImage: String? = nil

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(palette.accent)
                .frame(width: 5, height: 5)

            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(-0.24)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .foregroundStyle(palette.textMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(palette.surface.opacity(0.5))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}
