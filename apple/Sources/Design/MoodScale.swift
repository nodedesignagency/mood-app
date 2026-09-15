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

    /// The bar's face for this mood, resting and selected.
    ///
    /// Derived from `key` rather than stored, so the files and the scale
    /// cannot drift apart: renaming a mood renames what it looks for. Drop
    /// the artwork in `Sources/Resources` — see the README there.
    var icon: String { "mood-\(key)" }
    var iconSelected: String { "mood-\(key)-blue" }
}

enum MoodScale {
    // Derived in OKLCH from the two colours the file actually specifies —
    // the mood word's 3169EC and the glow's C5E0FF — so Okay is Figma's
    // exactly and the other four are the same colour at other hues.
    //
    // Lightness and chroma are not held constant across the ramp. They can't
    // be: a gold at the blue's lightness comes out brown, and a violet at the
    // gold's washes out. They are set per hue so all five read equally vivid.
    //
    // Each glow keeps its accent's hue less 11.6°, at 1.6× the lightness and
    // a quarter of the chroma — the relationship C5E0FF already has to
    // 3169EC. Adjacent moods therefore sit close and the ends read apart,
    // which is the right way round for something a thumb sweeps through.
    static let all: [Mood] = [
        Mood(id: 0, key: "awful", label: "Awful",
             accent: Color(hex: 0x6A43C4), glow: Color(hex: 0xD6DAFF), mascot: "mascot-awful"),
        Mood(id: 1, key: "low", label: "Low",
             accent: Color(hex: 0x565BE1), glow: Color(hex: 0xCCDDFF), mascot: "mascot-low"),
        Mood(id: 2, key: "okay", label: "Okay",
             accent: Color(hex: 0x3169EC), glow: Color(hex: 0xC5E0FF), mascot: "mascot-okay"),
        Mood(id: 3, key: "good", label: "Good",
             accent: Color(hex: 0x00AE67), glow: Color(hex: 0xC8E7C9), mascot: "mascot-good"),
        Mood(id: 4, key: "great", label: "Great",
             accent: Color(hex: 0xEFB300), glow: Color(hex: 0xF2D8B8), mascot: "mascot-great"),
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
        // Smoothstepped, not linear. A straight blend changes colour at a
        // constant rate and then turns a corner at every stop; that kink is
        // the second thing that read as lurching. Easing to a stop at each
        // end means the rate is zero exactly where a mood sits, so each one
        // holds its own colour for a moment before handing over.
        let eased = t * t * (3 - 2 * t)
        return channel(all[lower]).mix(with: channel(all[upper]), by: eased)
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
