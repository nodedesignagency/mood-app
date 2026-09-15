import SwiftUI

/// The mood word: all five of them on a drum, turned by the thumb.
///
/// There is no transition here, and that is the point. The words are laid out
/// once, one above the next, and `progress` turns the drum — so the word does
/// not change *into* another word, it rolls out of the window while its
/// neighbour rolls in, exactly as far as the thumb has moved and at exactly
/// the speed the thumb is moving. Nothing is timed, so nothing can be caught
/// half way, and the word rides the same curve as the chip and the glow
/// because it is driven by the same number they are.
///
/// Two attempts before this one put the outgoing and incoming words on top of
/// each other, centred, and cross-faded them. Both produced the same defect:
/// two words of different lengths, centred and part-way through a fade, fuse
/// into one unreadable word — "Loay" out of Low and Okay under the glyph-wise
/// `numericText`, and "Goay" out of Good and Okay under a letter-by-letter
/// fade. A drum cannot do that. Only one word is ever at the centre of the
/// window, the next is a whole line away, and the mask has taken the space
/// between them away before either can be read as part of the other.
///
/// Everything below is a pure function of `progress`, declared as
/// `animatableData` so SwiftUI recomputes it every frame rather than
/// interpolating the finished offsets.
struct MoodWord: View, Animatable {
    /// Continuous position along the scale, 0…4.
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Reduce Motion: the drum stops turning and the words simply dissolve
    /// into one another where they stand.
    @Environment(\.accessibilityReduceMotion) private var calm

    /// The turn from one word to the next. Small enough to read as a barrel
    /// rather than as a card flipping over.
    private static let step = Angle.degrees(22)
    /// ...and the distance that turn moves a word, at the centre of the
    /// window. A whole line, so the word leaving is clear of the window
    /// before the word arriving is inside it.
    private static let pitch: CGFloat = 58
    /// The barrel's radius follows from the two: pitch = radius · sin(step).
    private static let radius = pitch / CGFloat(sin(step.radians))

    /// The window the drum is seen through, taller than the word's 57pt slot
    /// on the artboard so the fade has somewhere to happen. What spills past
    /// the slot is nearly transparent, and the Continue button is drawn after
    /// the word, so it covers what little there is.
    private static let window: CGFloat = 76
    /// A word is whole within this of the centre and gone by `fadeEnd`.
    ///
    /// Both are measured against the font rather than guessed. At 44pt the
    /// line is 51.5pt and the ink runs from 14.4 above the word's centre to
    /// 25.7 below it — the tail of the "y" in Okay, which is the lowest
    /// thing on the scale — so 27 holds a resting word whole, tail included.
    /// Its neighbour is 58 away and its nearest ink 43.6, which is past 38,
    /// so only one word is ever in the window at rest. At the midpoint of a
    /// drag the two are 59.1 apart with 18.9pt of clear space between them:
    /// they cannot overlap, which is the whole reason for the drum.
    private static let fadeStart: CGFloat = 27
    private static let fadeEnd: CGFloat = 38

    /// How much a word softens, dims and draws back as it rolls away. Applied
    /// against the distance to the midpoint, so a word at rest is completely
    /// untouched: full colour, no blur, its own size.
    private static let maxBlur: CGFloat = 5
    private static let maxFade = 0.45
    private static let maxShrink: CGFloat = 0.10

    var body: some View {
        ZStack {
            ForEach(MoodScale.all) { mood in
                word(mood)
            }
        }
        .frame(height: Self.window)
        // A soft edge rather than a hard one: a word is not cut off at the
        // window, it thins out into the page, which is what keeps a drum from
        // reading as a list behind a letterbox.
        .mask { fade }
    }

    private func word(_ mood: Mood) -> some View {
        // Where this word sits relative to the window, in moods.
        let d = Double(mood.id) - progress
        let turn = calm ? 0 : d * Self.step.radians
        // Nothing is eased over time — this is eased over *distance*, so a
        // word holds its own colour and sharpness while the thumb is near it
        // and gives them up as the thumb leaves.
        let away = ease(min(1, abs(d) / 0.5))
        // A word only reaches the window within about 0.9 of a mood, so the
        // three that cannot be seen are not drawn or blurred. Five blurred
        // words a frame, at 120Hz, for three of them to be masked out.
        let near = abs(d) < 1.05

        return Text(mood.label)
            .tracking(Figma.wordTracking)
            // Each word carries its own mood's colour rather than the blend,
            // so the colour at rest is exactly the file's and the one rolling
            // past is honestly the next mood's.
            .foregroundStyle(mood.accent)
            .blur(radius: calm || !near ? 0 : Self.maxBlur * CGFloat(away))
            .opacity(!near ? 0 : (calm ? max(0, 1 - abs(d)) : 1 - Self.maxFade * away))
            .scaleEffect(1 - Self.maxShrink * CGFloat(away))
            .rotation3DEffect(.radians(turn), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
            .offset(y: calm ? 0 : CGFloat(sin(turn)) * Self.radius)
    }

    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.5 - Self.fadeEnd / Self.window),
                .init(color: .black, location: 0.5 - Self.fadeStart / Self.window),
                .init(color: .black, location: 0.5 + Self.fadeStart / Self.window),
                .init(color: .clear, location: 0.5 + Self.fadeEnd / Self.window),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Smoothstep: no corner where a word starts to leave, and none where it
    /// finishes arriving.
    private func ease(_ t: Double) -> Double { t * t * (3 - 2 * t) }
}
