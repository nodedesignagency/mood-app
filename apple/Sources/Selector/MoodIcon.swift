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
            if Self.artwork.contains(mood.id) {
                ZStack {
                    // The resting face stays fully opaque underneath and the
                    // blue fades in over it. Fading the two against each other
                    // instead would leave the glyph half transparent at the
                    // midpoint of a drag, which reads as the face dimming
                    // rather than changing colour.
                    Image(mood.icon).resizable().scaledToFit()
                    Image(mood.iconSelected).resizable().scaledToFit().opacity(selected)
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

    /// The moods whose artwork is actually present, resolved once.
    ///
    /// A `static let` so the bundle is searched on first use and never again:
    /// this is read for all five stops on every frame of a drag.
    private static let artwork: Set<Int> = Set(
        MoodScale.all
            .filter { UIImage(named: $0.icon) != nil && UIImage(named: $0.iconSelected) != nil }
            .map(\.id)
    )
}
