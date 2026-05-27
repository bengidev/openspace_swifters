import SwiftUI

struct OpenSpacePalette {
    let isDark: Bool
    let background: Color
    let backgroundSecondary: Color
    let surface: Color
    let elevatedSurface: Color
    let inverseSurface: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let border: Color
    let strongBorder: Color
    let accent: Color
    let accentSoft: Color
    let accentText: Color
    let success: Color
    let warning: Color
    let primaryActionFill: Color
    let primaryActionText: Color

    static func resolve(_ scheme: ColorScheme) -> OpenSpacePalette {
        if scheme == .dark {
            return OpenSpacePalette(
                isDark: true,
                background: Color(hex: "020202"),
                backgroundSecondary: Color(hex: "101010"),
                surface: Color(hex: "0a0a0a"),
                elevatedSurface: Color(hex: "161616"),
                inverseSurface: Color(hex: "eeeeee"),
                textPrimary: Color(hex: "eeeeee"),
                textSecondary: Color(hex: "a49d9a"),
                textMuted: Color(hex: "8a8380"),
                border: Color(hex: "3d3a39"),
                strongBorder: Color(hex: "4d4947"),
                accent: Color(hex: "ef6f2e"),
                accentSoft: Color(hex: "ee6018"),
                accentText: Color(hex: "ffffff"),
                success: Color(hex: "8cffb3"),
                warning: Color(hex: "ffcc7a"),
                primaryActionFill: Color(hex: "eeeeee"),
                primaryActionText: Color(hex: "020202")
            )
        }

        return OpenSpacePalette(
            isDark: false,
            background: Color(hex: "fafafa"),
            backgroundSecondary: Color(hex: "eeeeee"),
            surface: Color(hex: "ffffff"),
            elevatedSurface: Color(hex: "f5f5f5"),
            inverseSurface: Color(hex: "15130f"),
            textPrimary: Color(hex: "15130f"),
            textSecondary: Color(hex: "5e594f"),
            textMuted: Color(hex: "8c8577"),
            border: Color(hex: "d8d0c1"),
            strongBorder: Color(hex: "b8b3b0"),
            accent: Color(hex: "d15010"),
            accentSoft: Color(hex: "b74816"),
            accentText: Color(hex: "ffffff"),
            success: Color(hex: "137a42"),
            warning: Color(hex: "a15b08"),
            primaryActionFill: Color(hex: "15130f"),
            primaryActionText: Color(hex: "fafafa")
        )
    }
}
