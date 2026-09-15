import SwiftUI

/// The bundled artwork, resolved once at first use.
///
/// Everything here goes through `UIImage(named:)` rather than
/// `Image(_: String)`. The two are not the same lookup: `Image(_: String)`
/// names an image in an asset catalogue, and these are loose files copied
/// into the bundle, which is what `UIImage(named:)` is specified to search.
/// Naming them the other way draws nothing at all and reports no error,
/// which is exactly what happened the first time the faces landed. Resolving
/// here also means the bundle is searched at launch rather than on every
/// frame of a drag.
enum Art {
    /// A mood's face on the bar: resting, and the blue selected one.
    static func face(_ mood: Mood) -> (resting: UIImage, blue: UIImage)? { faces[mood.id] }

    /// A mood's mascot.
    static func mascot(_ mood: Mood) -> UIImage? { mascots[mood.id] }

    /// The sunburst behind the mascot — Figma's own render of "Star 2".
    static let rays = UIImage(named: "glow-rays")

    /// The hand in the hint line. The file has it as an SVG, which iOS will
    /// not load from a loose bundle file, so it ships rasterised at 3× with
    /// its 787878 already baked in — the same grey as the words beside it.
    static let hintSwipe = UIImage(named: "hint-swipe")

    private static let faces: [Int: (resting: UIImage, blue: UIImage)] = {
        var found: [Int: (resting: UIImage, blue: UIImage)] = [:]
        for mood in MoodScale.all {
            if let resting = UIImage(named: mood.icon),
               let blue = UIImage(named: mood.iconSelected) {
                found[mood.id] = (resting, blue)
            }
        }
        return found
    }()

    /// All five are drawn now — one per mood, named off each mood's `key`, so
    /// renaming a mood renames what it looks for. The shared stand-in the
    /// other four used to fall back to is gone with them.
    private static let mascots: [Int: UIImage] = {
        var found: [Int: UIImage] = [:]
        for mood in MoodScale.all {
            if let art = UIImage(named: mood.mascot) { found[mood.id] = art }
        }
        return found
    }()
}
