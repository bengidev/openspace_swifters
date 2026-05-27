import SwiftUI

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: OpenSpacePalette = .resolve(.light)
}

extension EnvironmentValues {
    var palette: OpenSpacePalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
