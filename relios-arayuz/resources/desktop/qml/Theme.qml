import QtQuick

pragma Singleton

QtObject {
    id: root

    // =========================================================================
    // Color Palette: Near-black + charcoal with cyan-to-green primary gradient
    // =========================================================================
    readonly property color bgBase: "#0B1017"        // Near-black main background
    readonly property color bgSurface: "#151F2B"     // Dark charcoal cards, sidebar, header, drawers
    readonly property color bgCard: "#1B2633"        // Slightly elevated card background
    readonly property color bgInput: "#0B1017"       // Text inputs, slider grooves, wells
    readonly property color bgInputHover: "#0F1620"  // Input hover state
    readonly property color bgHover: "#212E3D"       // General button / item hover state
    readonly property color bgPressed: "#263445"     // Button pressed state
    readonly property color bgSelected: "#22303F"    // Selected queue item or tab

    // Borders & Separators
    readonly property color borderSubtle: "#263445"  // Hairline panel borders
    readonly property color borderDefault: "#2E3E52" // Input / card borders
    readonly property color borderActive: "#3A4C63"  // Hovered / focused borders
    readonly property color borderAccent: "#F4A62A"  // Accent border

    // Primary Action Gradient (cyan-blue -> bright green -> deep green)
    readonly property color primaryGradStart: "#F4A62A" // Left side of button
    readonly property color primaryGradMid: "#F8B64C"   // Green highlight
    readonly property color primaryGradEnd: "#D98E1E"   // Right side of button

    // Technical Accents (green primary actions)
    readonly property color accent: "#F4A62A"        // Primary brand action color
    readonly property color accentHover: "#F8B64C"   // Primary action hover - always solid green
    readonly property color accentPressed: "#D98E1E" // Primary action pressed - darker green
    readonly property color primaryDisabled: "#B5832F"     // Disabled primary - still clearly green
    readonly property color primaryDisabledText: "#2A1E0A" // Text on disabled primary
    readonly property color accentGlow: "#20F4A62A"  // Subtle glow around active element
    readonly property color accentMuted: "#2E2614"   // Background tint for active pill tabs

    // Status Colors
    readonly property color success: "#2EC4D6"       // Complete / Ready / Online
    readonly property color successBg: "#10303A"
    readonly property color warning: "#FFD98E"       // Caution / HDR note
    readonly property color warningBg: "#2F2715"
    readonly property color danger: "#FF6B6B"        // Stop / Cancel / Error
    readonly property color dangerHover: "#FF8A8A"
    readonly property color dangerPressed: "#E05555"
    readonly property color dangerBg: "#3A1A1F"

    // Typography Colors
    readonly property color textPrimary: "#E6EDF5"   // High contrast off-white
    readonly property color textSecondary: "#8A9BB0" // Subdued labels & hints
    readonly property color textMuted: "#566476"     // Placeholders & disabled
    readonly property color textAccent: "#F8B64C"    // Accent highlighted values

    // =========================================================================
    // Typography Hierarchy
    // =========================================================================
    readonly property string fontFamily: {
        if (typeof backend !== "undefined" && backend) {
            const language = backend.language
            const choices = backend.languageChoices || []
            for (let i = 0; i < choices.length; ++i)
                if (choices[i].value === language) return choices[i].fontFamily
        }
        return Qt.application.font.family
    }
    readonly property string monoFontFamily: "Consolas"

    readonly property int fontSizeSmall: 11
    readonly property int fontSizeBody: 12
    readonly property int fontSizeLabel: 13
    readonly property int fontSizeSubtitle: 14
    readonly property int fontSizeTitle: 16
    readonly property int fontSizeHeader: 18

    // =========================================================================
    // Geometry & Metrics
    // =========================================================================
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 14

    readonly property int controlHeight: 32
    readonly property int controlHeightSmall: 26
    readonly property int controlHeightLarge: 38

    readonly property int spacingSmall: 6
    readonly property int spacingMedium: 10
    readonly property int spacingLarge: 16
    readonly property int spacingHuge: 24

    // =========================================================================
    // Transitions & Animations
    // =========================================================================
    readonly property int animFast: 120
    readonly property int animNormal: 200
    readonly property int animSlow: 300
}
