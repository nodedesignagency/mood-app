import SwiftUI

/// The mascot, and the way one mood's drawing becomes the next.
///
/// The five are separate illustrations rather than five frames of one pose:
/// different colours, different silhouettes — Awful has melted into a puddle
/// and Great is wearing sunglasses. Nothing can be interpolated between them.
/// A cross-fade puts half a purple blob over half a red puddle and reads as a
/// ghost, and an in-between generated from the two would have to invent the
/// melt and invent the sunglasses.
///
/// So the change is not blended at all. It is covered, which is what a cartoon
/// does with a pose it cannot tween: the character hops, and the drawing is
/// swapped at the top of the hop, where it is stretched, blurred and moving
/// fastest. On a mood it sits still and completely undistorted, because that
/// is when it is actually being looked at.
///
/// The hop is a function of `progress`, not of time: the character is on the
/// floor at every mood and at its highest exactly half way between two, so it
/// rises and falls under the thumb at the speed the thumb moves and lands when
/// the thumb lands. `animatableData` recomputes all of it every frame, and the
/// screen drives it with the same spring as the chip and the glow.
struct MoodMascot: View, Animatable {
    /// Continuous position along the scale, 0…4.
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Reduce Motion: no hop, no stretch, no blur. The drawing still changes
    /// — that is information, not decoration — it just changes in place.
    @Environment(\.accessibilityReduceMotion) private var calm

    /// How high the character rises between one mood and the next. 16 against
    /// a 392pt character: a bounce, not a jumping jack.
    private static let hop: CGFloat = 16
    /// How much it draws out and narrows at the top of that arc.
    private static let stretch: CGFloat = 0.055
    private static let narrow: CGFloat = 0.045
    /// Speed blur at the apex, which is also what covers the swap.
    private static let apexBlur: CGFloat = 2.5
    /// How much lower the character sits at Awful than at Great.
    private static let posture: CGFloat = 7

    /// Where the feet are, as a fraction of the mascot's 392pt box.
    ///
    /// Measured, not guessed: the four standing mascots land their feet within
    /// 3.1pt of each other, at 331pt down the box. Stretch and squash are
    /// anchored there rather than at the box's edge, so the character grows
    /// and compresses against the floor it is standing on.
    private static let feet = UnitPoint(x: 0.5, y: 331.0 / 392.0)

    var body: some View {
        // 0 sitting on a mood, 1 exactly half way to the next — which is also
        // where the drawing changes.
        let flight = calm ? 0 : min(1, abs(progress - progress.rounded()) * 2)
        // Eased, so the character leaves the floor and reaches the top without
        // a corner at either end.
        let eased = flight * flight * (3 - 2 * flight)

        art
            .scaleEffect(
                x: 1 - Self.narrow * CGFloat(eased),
                y: 1 + Self.stretch * CGFloat(eased),
                anchor: Self.feet
            )
            .blur(radius: Self.apexBlur * CGFloat(eased))
            // The arc itself. Sine rather than the eased value, so the top is
            // a real apex — the character is weightless there for a moment
            // instead of turning a corner.
            .offset(y: posture - Self.hop * CGFloat(sin(Double.pi / 2 * flight)))
    }

    /// The drawing for whichever mood is nearest. No transition and no
    /// `id` — the swap is a cut, and the hop is what hides it.
    @ViewBuilder
    private var art: some View {
        let mood = MoodScale.nearest(to: progress)
        if let drawn = Art.mascot(mood) {
            Image(uiImage: drawn)
                .resizable()
                .scaledToFit()
        } else {
            MoodFace(progress: progress, size: 190, color: MoodScale.accent(at: progress))
        }
    }

    /// Low moods sit lower and heavier, high ones ride higher. A straight line
    /// through the scale, so it is the thumb's position and nothing else.
    private var posture: CGFloat {
        calm ? 0 : Self.posture * CGFloat(1 - progress / 2)
    }
}
