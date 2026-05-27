import SwiftUI

enum AppTheme: String, Equatable {
    case system
    case light
    case dark

    func resolveColorScheme(_ systemScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .system:
            return systemScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var next: AppTheme {
        switch self {
        case .system: .light
        case .light: .dark
        case .dark: .system
        }
    }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var isDark: Bool {
        self == .dark
    }
}
