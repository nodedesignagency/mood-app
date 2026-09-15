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

    /// One mascot has been drawn so far, so a mood without its own falls back
    /// to the shared image. When the other four land as `mascot-<key>` they
    /// are picked up with no change here.
    private static let mascots: [Int: UIImage] = {
        let shared = UIImage(named: "mascot")
        var found: [Int: UIImage] = [:]
        for mood in MoodScale.all {
            if let art = UIImage(named: mood.mascot) ?? shared { found[mood.id] = art }
        }
        return found
    }()
}
