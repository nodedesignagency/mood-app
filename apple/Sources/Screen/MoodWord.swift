import SwiftUI

/// The mood word, and the way one word becomes the next.
///
/// A word does not cut, and it does not simply fade. It is set letter by
/// letter, and each letter runs the same journey a fraction of a beat behind
/// the one before it, so the word arrives as a wave rather than a block.
/// Letters come in blurred, a little small and a little spread apart, from
/// below when the mood is rising and from above when it is falling — the
/// direction of the change is visible before the word is even readable — and
/// each lands with a bounce. The word being replaced goes out the same way
/// the scale is now moving.
///
/// All of it is a function of one number per word, `life`:
///
///     0   waiting, off the screen's axis, invisible
///     1   home
///     2   gone, off the axis the other side
///
/// which is the whole reason it survives a thumb. `life` is `animatableData`,
/// so a spring drives it and can be retargeted from wherever it has got to: a
/// word interrupted half way in finishes arriving and then leaves, rather
/// than snapping back or starting again. That is exactly what the old
/// `numericText` transition could not do — it interpolated glyph by glyph,
/// being built for rolling digits, so an interrupted drag froze it part way
/// and left "Loay" and "G kay" on the screen.
struct MoodWord: View {
    /// The mood to name. Changing it is what starts a transition, and its
    /// `id` is what says which way the scale moved.
    var mood: Mood
    /// How far the thumb is between two moods: 0 sitting on one, 1 exactly
    /// half way between two.
    var crossing: Double

    /// Between two moods the word is neither of them, so it softens and draws
    /// back, and resolves as the thumb lands. The swap happens at exactly the
    /// midpoint, where this is deepest — so one word becoming another is
    /// covered by the same defocus that reads as depth.
    private static let crossBlur: CGFloat = 1.6
    private static let crossShrink: CGFloat = 0.04
    private static let crossFade: Double = 0.14

    /// Some people have asked the system for less of this. The word still
    /// changes and still carries the mood's colour — it simply stops
    /// travelling: no arc, no stagger, no bounce, no scaling. What is left is
    /// a dissolve, which is a change of state rather than a movement.
    @Environment(\.accessibilityReduceMotion) private var calm

    /// The word on screen, and at most one still leaving.
    @State private var words: [Word] = []
    /// Where each word has got to in its own life. Held here rather than
    /// inside the layer because SwiftUI interpolates only what a view
    /// declares as `animatableData`, and a value the layer held in `@State`
    /// would not be that: SwiftUI would animate the finished per-letter
    /// offsets instead, every letter on one curve, which is the stagger gone.
    @State private var life: [Int: Double] = [:]
    /// Ids are minted, never reused, so a word still leaving can never be
    /// mistaken for the word replacing it.
    @State private var minted = 0

    private struct Word: Identifiable {
        let id: Int
        let text: String
        /// Which way the scale moved when this word arrived: +1 up, -1 down.
        let rise: CGFloat
        /// ...and which way it was moving when this word was replaced. Set as
        /// the word starts to leave, so it goes the way the scale is going
        /// now rather than the way it came in. Otherwise a word that rose
        /// into place would leave upward into its replacement arriving from
        /// above, and the two would cross.
        var fall: CGFloat
    }

    var body: some View {
        ZStack {
            ForEach(words) { word in
                WordLayer(
                    text: word.text,
                    rise: word.rise,
                    fall: word.fall,
                    life: life[word.id] ?? 0,
                    calm: calm
                )
                // The innermost animation wins, which is the point of putting
                // it here: the screen wraps this whole view in the drag's own
                // curve so the colour follows the thumb, and without this
                // that curve would drive the letters too.
                .animation(
                    word.id == words.last?.id ? MoodMotion.wordEnter : MoodMotion.wordExit,
                    value: life[word.id]
                )
                .onAppear {
                    // A frame at life 0 has to reach the screen before the
                    // spring has anywhere to travel from, so the entrance
                    // starts here rather than where the word is added.
                    life[word.id] = 1
                }
                // A word on its way out is still on the screen for a moment.
                // It is not what the screen currently says.
                .accessibilityHidden(word.id != words.last?.id)
            }
        }
        .compositingGroup()
        .blur(radius: Self.crossBlur * CGFloat(crossing))
        .scaleEffect(1 - (calm ? 0 : Self.crossShrink) * CGFloat(crossing))
        .opacity(1 - Self.crossFade * crossing)
        // `initial` covers the first appearance as well, so the word arrives
        // when the screen does instead of being there already.
        .onChange(of: mood.id, initial: true) { was, now in
            show(mood.label, rise: now < was ? -1 : 1)
        }
    }

    private func show(_ text: String, rise: CGFloat) {
        // The word on screen starts leaving, from wherever its own entrance
        // had got to.
        if let leaving = words.indices.last {
            words[leaving].fall = rise
            life[words[leaving].id] = 2
        }

        // Only ever two: the word arriving and the one it replaced. On a fast
        // drag a third change lands before the first word has left, and
        // stacked ghosts read as mush rather than as motion. The oldest is
        // always the faintest, so it is the one to drop.
        while words.count > 1 {
            life[words.removeFirst().id] = nil
        }

        minted += 1
        words.append(Word(id: minted, text: text, rise: rise, fall: rise))
        life[minted] = 0
    }
}

/// One word, mid-flight. See `MoodWord` for what `life` means.
private struct WordLayer: View, Animatable {
    let text: String
    /// The direction the scale moved to bring this word in, and the direction
    /// it was moving when this word was replaced. Both are +1 up, -1 down.
    let rise: CGFloat
    let fall: CGFloat
    var life: Double
    /// Reduce Motion. Everything that travels is multiplied by `motion`, so
    /// this leaves the dissolve and takes away the rest.
    let calm: Bool

    private var motion: CGFloat { calm ? 0 : 1 }

    /// `life` is the animated quantity, so SwiftUI hands this view every
    /// value in between and rebuilds the body for each one. That is what
    /// makes the stagger possible: the letters' positions are never
    /// interpolated, they are recomputed from the one number that is.
    var animatableData: Double {
        get { life }
        set { life = newValue }
    }

    /// The share of the journey given over to the stagger: the first letter
    /// is home this much of it before the last one is. Whatever it is set to,
    /// the journey is compressed to fit, so every letter is home at life 1.
    private static let stagger = 0.42
    /// How far a letter travels, at its furthest from home.
    private static let travel: CGFloat = 20
    /// How far past home it carries before settling back.
    private static let overshoot = 1.4
    private static let maxBlur: CGFloat = 6.5
    /// How much wider apart the letters sit while they are away from home.
    private static let spread: CGFloat = 3
    private static let shrink: CGFloat = 0.14
    /// A letter is fully sharp and opaque within this much of home, so the
    /// bounce at the end reads as weight rather than as a flicker.
    private static let settled: CGFloat = 0.18

    var body: some View {
        let letters = Array(text)
        // One `Text` per letter, so the file's −1.38 tracking becomes the
        // stack's spacing — tracking is the space between glyphs, which is
        // what a stack spacing is. What the split costs is the font's own
        // kerning between pairs, which at this size is a fraction of a point
        // and is the price of being able to move a letter at all.
        HStack(spacing: Figma.wordTracking) {
            ForEach(letters.indices, id: \.self) { i in
                let letter = flight(of: i, in: letters.count)
                Text(String(letters[i]))
                    .scaleEffect(1 - Self.shrink * motion * letter.away)
                    .blur(radius: (1 - letter.presence) * Self.maxBlur)
                    .opacity(Double(letter.presence * letter.presence))
                    .offset(x: letter.x, y: letter.y)
            }
        }
        // Five `Text`s are five elements, and VoiceOver would otherwise read
        // the word out one letter at a time.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    /// Where one letter is, at this moment in the word's life.
    private struct Flight {
        var x: CGFloat
        var y: CGFloat
        /// Distance from home, 0…1 — and just past 0 on the bounce.
        var away: CGFloat
        /// 1 anywhere near home, 0 at full travel.
        var presence: CGFloat
    }

    private func flight(of i: Int, in n: Int) -> Flight {
        let stagger = calm ? 0 : Self.stagger
        let start = n > 1 ? stagger * Double(i) / Double(n - 1) : 0
        let span = 1 - stagger
        let arriving = Self.arrive(clamp01((life - start) / span))
        let leaving = Self.depart(clamp01((life - 1 - start) / span))

        // A letter is always home before it can begin to leave, so these two
        // never overlap: they sum rather than compete, and the sum is how far
        // from home the letter is.
        let away = CGFloat((1 - arriving) + leaving)
        let presence = min(1, max(0, (1 - away) / (1 - Self.settled)))

        return Flight(
            x: (CGFloat(i) - CGFloat(n - 1) / 2) * Self.spread * motion * away,
            // Arriving and leaving carry their own directions, and the
            // leaving term is exactly zero at the moment a word is replaced —
            // which is what lets a word reverse mid-flight without jumping.
            y: CGFloat(1 - arriving) * Self.travel * motion * rise
                - CGFloat(leaving) * Self.travel * motion * fall,
            away: away,
            presence: presence
        )
    }

    /// Ease out, past home, and back: the letter lands with weight instead of
    /// coasting to a stop.
    ///
    /// The entrance spring cannot do this on its own. It overshoots `life` by
    /// 2.6%, but the stagger has compressed what is left of the journey, and
    /// what comes out at the letter is a tenth of a point — which is the
    /// difference between a word that lands and one that just stops. Measured
    /// before this was written, not guessed.
    private static func arrive(_ t: Double) -> Double {
        let k = t - 1
        return 1 + (overshoot + 1) * k * k * k + overshoot * k * k
    }

    /// Ease in: the word being replaced hangs for a moment, then is pulled
    /// away.
    private static func depart(_ t: Double) -> Double { t * t }
}

private func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
