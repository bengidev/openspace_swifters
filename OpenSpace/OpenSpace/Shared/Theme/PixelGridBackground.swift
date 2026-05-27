import SwiftUI

struct PixelGridBackground: View {
    var spacing: CGFloat = 20
    var dotSize: CGFloat = 1.0
    var opacity = 0.06

    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { context, size in
            for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
                for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(palette.textPrimary.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
