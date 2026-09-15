import SwiftUI

/// One mood's face on the bar.
///
/// Two pieces of artwork per mood — the resting one and the blue selected one
/// — crossfaded by how close the chip is. Dragging therefore hands the colour
/// from one face to the next continuously rather than switching it at the
/// moment a mood is crossed.
///
/// Until the artwork is in the bundle this falls back to the face drawn in
/// `MoodFace`, tinted from ink toward the mood's accent by the same value, so
/// the screen behaves identically with or without the assets.
struct MoodIcon: View {
    let mood: Mood
    let size: CGFloat
    /// 0 at rest, 1 when the chip is centred on this stop.
    let selected: Double

    var body: some View {
        Group {
            if let art = Self.art[mood.id] {
                ZStack {
                    // The resting face stays fully opaque underneath and the
                    // blue fades in over it. Fading the two against each other
                    // instead would leave the glyph half transparent at the
                    // midpoint of a drag, which reads as the face dimming
                    // rather than changing colour.
                    Image(uiImage: art.resting).resizable().scaledToFit()
                    Image(uiImage: art.blue).resizable().scaledToFit()
                        .opacity(selected)
                }
            } else {
                MoodFace(
                    progress: Double(mood.id),
                    size: size,
                    color: Figma.iconInk.mix(with: mood.accent, by: selected)
                )
            }
        }
        .frame(width: size, height: size)
    }

    /// The artwork, loaded once and held by mood id.
    ///
    /// Loaded through `UIImage(named:)` and handed over as an image rather
    /// than named with `Image(_: String)`. The two are not documented to do
    /// the same thing: `Image(_: String)` names an image *in an asset
    /// catalogue*, and these are loose files copied into the bundle, which is
    /// what `UIImage(named:)` is specified to search. Doing it here also means
    /// the bundle is searched five times at launch instead of on every frame
    /// of a drag.
    private static let art: [Int: (resting: UIImage, blue: UIImage)] = {
        var found: [Int: (resting: UIImage, blue: UIImage)] = [:]
        for mood in MoodScale.all {
            if let resting = UIImage(named: mood.icon),
               let blue = UIImage(named: mood.iconSelected) {
                found[mood.id] = (resting, blue)
            }
        }
        return found
    }()
}
