import SwiftUI

/// The screen arriving.
///
/// One number runs 0 → 1 for the whole screen and every element takes its own
/// slice of it: `delay` is where that element belongs in the order and `span`
/// is how long it takes. That is the whole stagger — no per-element timer, no
/// chain of completions, nothing that can be left half-finished if the screen
/// goes away mid-arrival.
///
/// `phase` is `animatableData`, so SwiftUI hands this modifier every value in
/// between and each element's position is recomputed from it rather than
/// interpolated. Without that they would all travel on one curve and arrive
/// together, which is the stagger gone.
///
/// Everything here moves on one shape — `settle` — and the rule it has to keep
/// is that nothing changes direction on the way in. That rule is not taste. A
/// recording of the previous arrival, stepped frame by frame, had the
/// character reverse six times in the 26 frames of its entrance and jump 11%
/// of its own height between two consecutive frames. Both were read as the
/// app being broken, and both were arithmetic:
///
///   * `easeOutBounce` was driving a journey that ran *upward* (see `fall`),
///     so the character shot past its mark and bounced back down off nothing.
///   * the landing squash was a step followed by an exponential decay whose
///     time constant worked out at 32ms — under two frames — so it arrived
///     whole in one frame and was gone before the eye could call it a squash.
struct Entrance: ViewModifier, Animatable {
    /// 0 as the screen appears, 1 once everything has arrived.
    var phase: Double
    /// Where this element falls in the order, as a share of the arrival.
    var delay: Double
    /// How much of the arrival this element takes. `delay + span` must land
    /// on or before 1, or the element never finishes arriving.
    var span: Double
    /// How far it travels on the way in, rising into place from below.
    var rise: CGFloat
    /// How much smaller it starts, for things that pop rather than travel.
    var zoom: CGFloat
    /// If set, the element *falls* this far into place, from above, and
    /// cushions as it lands.
    ///
    /// Above, which is the correction. This was `drop` and was applied as a
    /// positive `offset(y:)` — and a positive y in SwiftUI is *down the
    /// screen*, so the character began 120pt below where it belonged and rose
    /// into place. Nothing in the file said so and the comment at the call
    /// site said the opposite. The name carries the direction now.
    var fall: CGFloat
    /// What a landing cushions against. The mascot's is its feet.
    var anchor: UnitPoint

    /// Reduce Motion keeps the order and the fade and drops the movement.
    @Environment(\.accessibilityReduceMotion) private var calm

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    /// How far past its place a rising element carries before settling.
    ///
    /// One overshoot, on the way to rest, is a spring and reads as life. It is
    /// not what the bounce was: that was six reversals with no spring behind
    /// them.
    private static let overshoot: Double = 0.7

    /// A falling element is faded in over the first part of its slice rather
    /// than across all of it, or it would still be turning up as it lands and
    /// the fall would never be seen. At 15% the character is solid 123ms in
    /// with 72 of its 120pt still to come down.
    private static let fadeInBy = 0.15

    /// How stiff the settle is. 9.2 puts the element within a tenth of a
    /// point of its mark by the end of its slice, so the tail is finished
    /// rather than cut off.
    private static let stiffness: Double = 9.2
    /// ...and what the curve reaches at t = 1, so it can be divided out and
    /// the element lands exactly on its mark rather than a fraction short.
    private static let reach = 1 - (1 + stiffness) * exp(-stiffness)

    /// Where the landing cushion sits inside the slice, how long it lasts and
    /// how deep it goes.
    ///
    /// It opens at 0.55, by which point the character is 96% of the way down —
    /// four and a half points off the floor and closing — and peaks at 0.72,
    /// a point and a half off it. So it compresses into contact rather than
    /// in mid-air, which is where the old one fired.
    private static let cushionAt = 0.55
    private static let cushionFor = 0.34
    private static let cushionBy: CGFloat = 0.06

    func body(content: Content) -> some View {
        let t = min(1, max(0, (phase - delay) / span))
        let eased = t * t * (3 - 2 * t)
        let falling = fall != 0 && !calm

        // Where it is: a fall that lands and cushions, or a rise that carries
        // a little past its mark and comes back.
        let travel: CGFloat
        let fade: Double
        if falling {
            // Negative is up the screen, so it starts above its place.
            travel = -CGFloat(1 - Self.settle(t)) * fall
            let f = min(1, t / Self.fadeInBy)
            fade = f * f * (3 - 2 * f)
        } else {
            let k = t - 1
            let placed = 1 + (Self.overshoot + 1) * k * k * k + Self.overshoot * k * k
            travel = calm ? 0 : CGFloat(1 - placed) * rise
            fade = eased
        }

        let away = CGFloat(1 - eased)
        let squash = falling ? Self.cushion(t) : 0

        return content
            // A landing spreads what it lands on: wider as it is flattened,
            // though only half as much sideways as down. A cushion gives at
            // the knees; it does not splat.
            .scaleEffect(
                x: calm ? 1 : 1 - zoom * away + squash * 0.5,
                y: calm ? 1 : 1 - zoom * away - squash,
                anchor: anchor
            )
            .opacity(fade)
            .offset(y: travel)
    }

    /// A fall that comes to rest: the step response of a critically damped
    /// spring, normalised so it lands exactly on its mark.
    ///
    /// Critically damped is the point — it is the fastest approach that cannot
    /// overshoot, so the curve is monotone by construction and the character
    /// physically cannot reverse on the way down. It leaves at rest, gathers
    /// speed, and eases into the floor.
    private static func settle(_ t: Double) -> Double {
        if t <= 0 { return 0 }
        if t >= 1 { return 1 }
        return (1 - (1 + stiffness * t) * exp(-stiffness * t)) / reach
    }

    /// How compressed the landing has it: a raised cosine over `cushionFor`.
    ///
    /// Zero value *and* zero slope at both ends, which is what keeps it from
    /// being seen as a pop. It takes 74ms to reach its full 6% rather than
    /// arriving inside one frame at 11%, and it lets go the same way it
    /// arrived instead of decaying out from under the character.
    private static func cushion(_ t: Double) -> CGFloat {
        let u = (t - cushionAt) / cushionFor
        guard u > 0, u < 1 else { return 0 }
        return cushionBy * 0.5 * (1 - CGFloat(cos(2 * Double.pi * u)))
    }
}

/// The light coming up, and taking the weight when the character lands.
///
/// The glow does not fade in, it *ignites*: it comes up from under half its
/// size, carries a little past full and settles. Then the character lands on
/// it and it gives once, which is the one moment in the arrival where two
/// things are aware of each other.
///
/// It used to turn 9° on the way in as well, and it applied to the ray texture
/// along with the light. `.softLight` is a blend mode and a blend mode is
/// composited offscreen, so that rotation re-ran a full-screen offscreen pass
/// on every frame of the arrival. Removing one of those from the second the
/// app is busiest is the same move as the one that turned the glow's Gaussian
/// into a gradient. This modifier is the light alone now — the rays fade up
/// beside it and never move, which costs the sweep; 9° of a white-on-white
/// texture at soft light is a cheap thing to give back for the frames.
struct Ignite: ViewModifier, Animatable {
    var phase: Double
    /// The phase at which the character touches down.
    var impact: Double

    @Environment(\.accessibilityReduceMotion) private var calm

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    private static let span = 0.40
    /// How small the light starts.
    private static let from: CGFloat = 0.45
    /// How far the landing pushes the light out, and over how much of the
    /// arrival that happens. A raised cosine again, for the same reason the
    /// character's cushion is one: a step here was a visible tick in the
    /// backdrop at the exact moment the eye was on the character.
    private static let give: CGFloat = 0.05
    private static let giveFor = 0.16

    func body(content: Content) -> some View {
        let t = min(1, max(0, phase / Self.span))
        let eased = t * t * (3 - 2 * t)
        let k = t - 1
        let placed = CGFloat(1 + 2.4 * k * k * k + 1.4 * k * k)
        let grown = Self.from + (1 - Self.from) * placed

        let u = (phase - impact) / Self.giveFor
        let hit = u > 0 && u < 1
            ? Self.give * 0.5 * (1 - CGFloat(cos(2 * Double.pi * u)))
            : 0

        return content
            .scaleEffect(calm ? 1 : grown + hit)
            .opacity(eased)
    }
}

extension View {
    /// Arrive with the screen. See `Entrance`.
    func entrance(
        _ phase: Double,
        delay: Double,
        span: Double = 0.30,
        rise: CGFloat = 0,
        zoom: CGFloat = 0,
        fall: CGFloat = 0,
        anchor: UnitPoint = .center
    ) -> some View {
        modifier(Entrance(phase: phase, delay: delay, span: span, rise: rise,
                          zoom: zoom, fall: fall, anchor: anchor))
    }

    /// Come up like a light being switched on. See `Ignite`.
    func ignite(_ phase: Double, impact: Double) -> some View {
        modifier(Ignite(phase: phase, impact: impact))
    }
}
