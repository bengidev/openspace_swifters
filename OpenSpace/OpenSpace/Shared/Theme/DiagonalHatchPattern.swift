import SwiftUI

struct DiagonalHatchPattern: View {
    var spacing: CGFloat = 10
    var opacity = 0.025

    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { context, size in
            for offset in stride(from: -size.height, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: offset, y: size.height))
                path.addLine(to: CGPoint(x: offset + size.height, y: 0))
                context.stroke(path, with: .color(palette.textPrimary.opacity(opacity)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}
