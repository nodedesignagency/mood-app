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
    /// True while a thumb is on the bar. The idle clip only runs when the
    /// character is standing on a mood rather than travelling between two.
    var isDragging: Bool

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

    /// The drawing for whichever mood is nearest, and its idle clip over the
    /// top where one exists. No transition and no `id` on the drawing — the
    /// swap is a cut, and the hop is what hides it.
    ///
    /// The clip is not a replacement for the still, it is laid over it: its
    /// first frame is that still, so the two agree exactly at the moment it
    /// starts and at every loop. A mood with no clip keeps the still and
    /// nothing else changes.
    @ViewBuilder
    private var art: some View {
        let mood = MoodScale.nearest(to: progress)
        ZStack {
            if let drawn = Art.mascot(mood) {
                Image(uiImage: drawn)
                    .resizable()
                    .scaledToFit()
            } else {
                MoodFace(progress: progress, size: 190, color: MoodScale.accent(at: progress))
            }

            if let clip = Art.idle(mood) {
                LoopingVideo(url: clip, isPlaying: settled)
                    // The clip carries the glow baked into it, because it was
                    // generated from a frame that had it. That glow came from
                    // the same numbers the screen draws its own with, so the
                    // two match — but only to the accuracy of an H.264 frame,
                    // and a rectangle is unforgiving. The edges are faded out
                    // so there is no rectangle to notice; the character's own
                    // ink starts 51pt in, well clear of it.
                    .mask { edgeFade }
                    // ...and that baked glow is also why the clip is hidden
                    // the moment the character is not standing still. The hop
                    // scales and lifts everything inside this stack, and the
                    // still can take that because it is transparent around the
                    // character — the screen's own glow shows through it. The
                    // clip cannot: its glow would be lifted and stretched with
                    // it, and slide against the one behind.
                    .opacity(settled ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
    }

    /// Standing still on a mood, with no thumb on the bar: the only state in
    /// which the idle clip is shown.
    ///
    /// The release spring is still running for a moment after a thumb lifts,
    /// and `progress` is not quite on a mood yet, so this waits for it. It
    /// costs nothing to wait: frame 0 of the clip is the still, so whichever
    /// of the two is on screen, the pixels are the same.
    private var settled: Bool {
        !isDragging && abs(progress - progress.rounded()) < 0.01
    }

    /// Opaque through the middle, fading out over the last 30pt or so.
    private var edgeFade: some View {
        Rectangle()
            .inset(by: 18)
            .fill(.black)
            .blur(radius: 10)
    }

    /// Low moods sit lower and heavier, high ones ride higher. A straight line
    /// through the scale, so it is the thumb's position and nothing else.
    private var posture: CGFloat {
        calm ? 0 : Self.posture * CGFloat(1 - progress / 2)
    }
}
