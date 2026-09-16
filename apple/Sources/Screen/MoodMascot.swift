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
    /// True while a thumb is on the bar. The idle clip runs the moment it
    /// lifts, and fades in as the character lands.
    var isDragging: Bool
    /// False until the screen has finished arriving. The clip waits for it
    /// for the same reason it waits out a hop: it carries a baked glow, and
    /// the arrival drops the character 24pt through a glow that is still
    /// blooming in behind it.
    var arrived: Bool

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
    /// The last part of a hop, across which the idle clip fades in. Half of
    /// it: the glow the clip carries is a gradient blurred at 82pt, so
    /// sliding it a few points against the one behind is not something the
    /// eye has an edge to catch it by, and arriving early matters more.
    private static let clipFadeIn = 0.5

    /// Where the feet are, as a fraction of the mascot's 392pt box.
    ///
    /// Measured, not guessed: the four standing mascots land their feet within
    /// 3.1pt of each other, at 331pt down the box. Stretch and squash are
    /// anchored there rather than at the box's edge, so the character grows
    /// and compresses against the floor it is standing on.
    /// Not private: the screen's arrival squashes the character against this
    /// same floor when it lands.
    static let feet = UnitPoint(x: 0.5, y: 331.0 / 392.0)

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
        let clip = Art.idle(mood)
        ZStack {
            if let drawn = Art.mascot(mood) {
                Image(uiImage: drawn)
                    .resizable()
                    .scaledToFit()
            } else {
                MoodFace(progress: progress, size: 190, color: MoodScale.accent(at: progress))
            }

            // Always here, even for the four moods that have no clip yet:
            // taking it out of the tree and putting it back is what made the
            // character slow to come alive. See `LoopingVideo`.
            LoopingVideo(url: clip)
                // The clip carries the glow baked into it, because it was
                // generated from a frame that had it. That glow came from the
                // same numbers the screen draws its own with, so the two
                // match — but only to the accuracy of an H.264 frame, and a
                // rectangle is unforgiving. The edges are faded out so there
                // is no rectangle to notice; the character's own ink starts
                // 51pt in, well clear of it.
                .mask { edgeFade }
                // A mood with no clip of its own shows none: the player holds
                // the last one it loaded, ready for the way back, and this is
                // what keeps it from being seen under the wrong mood.
                .opacity(clip == nil ? 0 : clipOpacity)
                .allowsHitTesting(false)
        }
    }

    /// How much of the idle clip is showing: none while a thumb is down, and
    /// fading in across the second half of the character's landing.
    ///
    /// This used to wait for the release spring to have properly finished —
    /// `progress` within 0.01 of a mood — and that is a long time to wait. The
    /// spring's envelope decays at 9.27 a second, so a thumb lifted half a
    /// mood out left the character standing there for 422ms before it so much
    /// as breathed, which reads as the animation being slow to start rather
    /// than as anything landing.
    ///
    /// It does not have to be a switch. The reason for waiting at all is that
    /// the clip carries a baked glow and the hop lifts and stretches
    /// everything in that stack — the still can take that, because it is
    /// transparent around the character and the screen's own glow shows
    /// through it, but the clip's glow would slide against the one behind.
    /// That only matters while the hop is big, and by half way down it is
    /// not: 11.3pt of lift and 2.8% of stretch at the point the clip starts
    /// to appear, 6.1pt and 0.9% by the time it is half way in, and both at
    /// zero as it reaches full. A gradient blurred at 82pt slid by six points
    /// gives the eye no edge to catch it by, which is the whole reason this
    /// can start early. It arrives as the character lands rather than after
    /// it has finished landing.
    ///
    /// The clip is already running by then, and was running throughout the
    /// drag: `LoopingVideo` plays whenever it has something to play and only
    /// holds for a mood with no clip at all. So none of this is ever waiting
    /// on a player to start — it is only deciding when to show one.
    private var clipOpacity: Double {
        guard arrived, !isDragging else { return 0 }
        let flight = min(1, abs(progress - progress.rounded()) * 2)
        return max(0, 1 - flight / Self.clipFadeIn)
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
