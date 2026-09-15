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
    // Red for Awful through blue for Okay to a dark amber for Great, with
    // Okay pinned to the two colours the file actually specifies — the mood
    // word's 3169EC and the glow's C5E0FF. Hues run the short way round from
    // red to blue (through magenta) and on to orange (through green), so a
    // drag never passes through a colour that is not on the scale.
    //
    // Each was solved, not picked. Lightness and chroma are set per hue to be
    // the most vivid colour sRGB can hold that still clears about 4:1 against
    // the backdrop it is actually read on. That backdrop is not the glow
    // colour itself: the word sits 133 points below the glow's centre, where
    // the blur has it at 79% over the page, so the measurement is taken
    // there. Okay is the file's and comes out at 3.74:1, which is why the
    // contrast looked thin — it is below 4.5 but above the 3:1 that applies
    // to text this size, and it sets the standard the rest match.
    //
    // Green is the dark one because it has to be: sRGB holds very little
    // chroma at a lightness dark enough to read on a pale tint, so pushing it
    // brighter only clips and turns it muddy.
    //
    // Great is the one place the 4:1 rule is relaxed, to 3.32:1, because at
    // 4:1 there is no orange — dark orange *is* brown, and every colour that
    // cleared the bar read as bronze. Moving its hue from 70 to 52 buys back
    // some of it, since sRGB holds more chroma there, and the rest comes from
    // accepting a ratio that still clears the 3:1 that applies to text this
    // size. It is the brightest orange available on that budget.
    //
    // Each glow keeps its accent's hue less 11.6° at 1.6x the lightness and a
    // quarter of the chroma — the relationship C5E0FF already has to 3169EC.
    static let all: [Mood] = [
        Mood(id: 0, key: "awful", label: "Awful",
             accent: Color(hex: 0xD7001F), glow: Color(hex: 0xFDD0D3), mascot: "mascot-awful"),
        Mood(id: 1, key: "low", label: "Low",
             accent: Color(hex: 0x9D2FA8), glow: Color(hex: 0xE9D4F6), mascot: "mascot-low"),
        Mood(id: 2, key: "okay", label: "Okay",
             accent: Color(hex: 0x3169EC), glow: Color(hex: 0xC5E0FF), mascot: "mascot-okay"),
        Mood(id: 3, key: "good", label: "Good",
             accent: Color(hex: 0x007D5B), glow: Color(hex: 0xC3E8CF), mascot: "mascot-good"),
        Mood(id: 4, key: "great", label: "Great",
             accent: Color(hex: 0xC55A00), glow: Color(hex: 0xFCD2C4), mascot: "mascot-great"),
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
