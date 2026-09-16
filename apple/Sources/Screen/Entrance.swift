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
struct Entrance: ViewModifier, Animatable {
    /// 0 as the screen appears, 1 once everything has arrived.
    var phase: Double
    /// Where this element falls in the order, as a share of the arrival.
    var delay: Double
    /// How much of the arrival this element takes. `delay + span` must land
    /// on or before 1, or the element never finishes arriving.
    var span: Double
    /// How far it travels on the way in, rising into place.
    var rise: CGFloat
    /// How much smaller it starts, for things that pop rather than travel.
    var zoom: CGFloat
    /// If set, the element *falls* this far instead, and bounces on landing.
    var drop: CGFloat
    /// What a landing squashes against. The mascot's is its feet.
    var anchor: UnitPoint

    /// Reduce Motion keeps the order and the fade and drops the movement.
    @Environment(\.accessibilityReduceMotion) private var calm

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    /// How far past its place a rising element carries before settling.
    private static let overshoot: Double = 1.2

    /// A falling element is faded in over the first part of its slice rather
    /// than across all of it, or it would still be turning up as it lands and
    /// the fall would never be seen.
    private static let dropFadeIn = 0.15

    /// Where a fall touches down, and how hard, as fractions of the slice.
    ///
    /// `easeOutBounce` touches four times; the fourth lands exactly at the
    /// end of the journey, and a squash fired there would still be recovering
    /// when the element is supposed to be at rest — the character would sit
    /// permanently flattened. Three, and whatever is left of them at the end
    /// is subtracted, so it comes to rest at exactly its own shape.
    private static let impacts: [(at: Double, amount: CGFloat)] =
        [(1 / 2.75, 0.17), (2 / 2.75, 0.095), (2.5 / 2.75, 0.05)]
    private static let recovery = 0.05

    func body(content: Content) -> some View {
        let t = min(1, max(0, (phase - delay) / span))
        let eased = t * t * (3 - 2 * t)
        let falling = drop != 0 && !calm

        // Where it is: a fall that bounces, or a rise that carries past its
        // mark and comes back.
        let travel: CGFloat
        let fade: Double
        if falling {
            travel = CGFloat(1 - Self.bounce(t)) * drop
            let f = min(1, t / Self.dropFadeIn)
            fade = f * f * (3 - 2 * f)
        } else {
            let k = t - 1
            let placed = 1 + (Self.overshoot + 1) * k * k * k + Self.overshoot * k * k
            travel = calm ? 0 : CGFloat(1 - placed) * rise
            fade = eased
        }

        let away = CGFloat(1 - eased)
        let squash = falling ? Self.squash(t) : 0

        return content
            // A landing spreads what it lands on: wider as it is flattened.
            .scaleEffect(
                x: calm ? 1 : 1 - zoom * away + squash * 0.85,
                y: calm ? 1 : 1 - zoom * away - squash,
                anchor: anchor
            )
            .opacity(fade)
            .offset(y: travel)
    }

    /// An accelerating fall that bounces: `easeOutBounce`, 0 → 1.
    private static func bounce(_ t: Double) -> Double {
        let n = 7.5625, d = 2.75
        if t < 1 / d { return n * t * t }
        if t < 2 / d { let t = t - 1.5 / d; return n * t * t + 0.75 }
        if t < 2.5 / d { let t = t - 2.25 / d; return n * t * t + 0.9375 }
        let t = t - 2.625 / d
        return n * t * t + 0.984375
    }

    /// How flattened it is: a hit at each touchdown, springing back out of it.
    private static func squash(_ t: Double) -> CGFloat {
        func hits(_ x: Double) -> CGFloat {
            impacts.reduce(CGFloat(0)) { total, impact in
                x >= impact.at
                    ? total + impact.amount * CGFloat(exp(-(x - impact.at) / recovery))
                    : total
            }
        }
        return max(0, hits(t) - hits(1))
    }
}

/// The light coming up, and taking the hit when the character lands.
///
/// The glow does not fade in, it *ignites*: it comes up from under half its
/// size, carries a little past full and settles, turning as it does so the
/// rays sweep round rather than simply appearing. Then the character lands on
/// it and it pushes out once, which is the one moment in the arrival where two
/// things are aware of each other.
struct Ignite: ViewModifier, Animatable {
    var phase: Double
    /// The phase at which the character touches down.
    var impact: Double

    @Environment(\.accessibilityReduceMotion) private var calm

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    private static let span = 0.42
    /// How small the light starts.
    private static let from: CGFloat = 0.45
    /// How far the rays sweep round on their way in.
    private static let sweep = -9.0
    /// How far the landing pushes the light out, and how fast that settles.
    private static let pulse: CGFloat = 0.05
    private static let recovery = 0.07

    func body(content: Content) -> some View {
        let t = min(1, max(0, phase / Self.span))
        let eased = t * t * (3 - 2 * t)
        let k = t - 1
        let placed = CGFloat(1 + 2.4 * k * k * k + 1.4 * k * k)
        let grown = Self.from + (1 - Self.from) * placed

        let since = phase - impact
        let hit = since >= 0 ? Self.pulse * CGFloat(exp(-since / Self.recovery)) : 0

        return content
            .scaleEffect(calm ? 1 : grown + hit)
            .rotationEffect(.degrees(calm ? 0 : Self.sweep * (1 - eased)))
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
        drop: CGFloat = 0,
        anchor: UnitPoint = .center
    ) -> some View {
        modifier(Entrance(phase: phase, delay: delay, span: span, rise: rise,
                          zoom: zoom, drop: drop, anchor: anchor))
    }

    /// Come up like a light being switched on. See `Ignite`.
    func ignite(_ phase: Double, impact: Double) -> some View {
        modifier(Ignite(phase: phase, impact: impact))
    }
}
