import SwiftUI

/// One point on the mood scale.
///
/// The selector's position is continuous, so every colour here doubles as an
/// interpolation keyframe: dragging between two moods blends them.
struct Mood: Identifiable, Equatable {
    let id: Int
    /// Stable key, safe to persist.
    let key: String
    /// The hero word.
    let label: String
    /// Accent used for the hero word and the chip's tint.
    let accent: Color
    /// Tint of the glow behind the mascot.
    let glow: Color
    /// Asset name for the mascot at this mood. Swapped for video later.
    let mascot: String
}

enum MoodScale {
    // PLACEHOLDER COLOURS — read off the mockup, not from the Figma file.
    // Replace with the real values (see apple/README.md).
    static let all: [Mood] = [
        Mood(id: 0, key: "awful", label: "Awful",
             accent: Color(hex: 0x6C63C7), glow: Color(hex: 0xD9D6F5), mascot: "mascot-awful"),
        Mood(id: 1, key: "low", label: "Low",
             accent: Color(hex: 0x4C9FDE), glow: Color(hex: 0xD3E7F8), mascot: "mascot-low"),
        Mood(id: 2, key: "okay", label: "Okay",
             accent: Color(hex: 0x0A7CFF), glow: Color(hex: 0xCFE4FA), mascot: "mascot-okay"),
        Mood(id: 3, key: "good", label: "Good",
             accent: Color(hex: 0x2FBF71), glow: Color(hex: 0xD4F0DF), mascot: "mascot-good"),
        Mood(id: 4, key: "great", label: "Great",
             accent: Color(hex: 0xFFB020), glow: Color(hex: 0xFCEBCB), mascot: "mascot-great"),
    ]

    static let last = all.count - 1

    /// Nearest mood to a continuous position, clamped to the scale.
    static func nearest(to progress: Double) -> Mood {
        all[min(last, max(0, Int(progress.rounded())))]
    }

    /// Blend two adjacent moods' accents at a continuous position.
    ///
    /// `Color.mix(with:by:)` interpolates perceptually, which keeps the blend
    /// from dipping through a muddy midpoint the way naive RGB lerping does.
    static func accent(at progress: Double) -> Color {
        blend(progress) { $0.accent }
    }

    static func glow(at progress: Double) -> Color {
        blend(progress) { $0.glow }
    }

    private static func blend(_ progress: Double, _ channel: (Mood) -> Color) -> Color {
        let clamped = min(Double(last), max(0, progress))
        let lower = Int(clamped)
        let upper = min(last, lower + 1)
        let t = clamped - Double(lower)
        return channel(all[lower]).mix(with: channel(all[upper]), by: t)
    }
}

extension Color {
    /// 0xRRGGBB literal, so the palette reads like the Figma values it came from.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
