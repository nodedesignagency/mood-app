import SwiftUI

/// The screen arriving.
///
/// One number runs 0 → 1 for the whole screen and every element takes its own
/// slice of it: `delay` is where that element belongs in the order and `span`
/// is how much of the arrival each one takes, so a later element is still on
/// its way in while an earlier one is settling. That is the whole stagger —
/// there is no per-element timer, no chain of completions, and nothing that
/// can be left half-finished if the screen goes away mid-arrival.
///
/// `phase` is `animatableData`, so SwiftUI hands this modifier every value in
/// between and each element's offset is recomputed from it rather than
/// interpolated. Without that the elements would all travel on one curve and
/// arrive together, which is the stagger gone — the same thing that made the
/// mood word's letters need it.
struct Entrance: ViewModifier, Animatable {
    /// 0 as the screen appears, 1 once everything has arrived.
    var phase: Double
    /// Where this element falls in the order, as a share of the arrival.
    var delay: Double
    /// How far it travels on the way in. Negative falls from above.
    var rise: CGFloat
    /// How much smaller it starts, for things that bloom rather than travel.
    var zoom: CGFloat

    /// Reduce Motion keeps the order and the fade and drops the movement.
    @Environment(\.accessibilityReduceMotion) private var calm

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    /// How much of the arrival one element takes. The last `delay` plus this
    /// has to land on or before 1, or that element never finishes arriving.
    static let span = 0.55

    /// How far past its place an element carries before settling back.
    private static let overshoot = 1.2

    func body(content: Content) -> some View {
        let t = min(1, max(0, (phase - delay) / Self.span))
        // Ease out, past the mark, and back. A spring driving `phase` cannot
        // give this: by the time it overshoots, the stagger has compressed
        // what is left of each element's own slice to nothing.
        let k = t - 1
        let placed = 1 + (Self.overshoot + 1) * k * k * k + Self.overshoot * k * k
        let away = CGFloat(1 - placed)

        return content
            .opacity(t * t * (3 - 2 * t))
            .scaleEffect(calm ? 1 : 1 - zoom * away)
            .offset(y: calm ? 0 : away * rise)
    }
}

extension View {
    /// Arrive with the screen. See `Entrance`.
    func entrance(_ phase: Double, delay: Double, rise: CGFloat = 0, zoom: CGFloat = 0) -> some View {
        modifier(Entrance(phase: phase, delay: delay, rise: rise, zoom: zoom))
    }
}
