import SwiftUI

/// Geometry for the curved mood bar.
///
/// The bar is a symmetric quadratic Bézier: it starts and ends at the same
/// height and arcs in the middle. Because the control point sits exactly
/// halfway between the endpoints horizontally, the x term collapses to a
/// straight line:
///
///     x(t) = (1-t)²·x0 + 2t(1-t)·midX + t²·x1  ≡  x0 + (x1 - x0)·t
///
/// That is the whole reason for this shape. Finger-x maps to bar position with
/// one divide — no arc-length table, no Newton iteration per frame — while y
/// still bends, and evenly spaced stops stay evenly spaced on screen.
///
/// Two spans matter, and they are not the same one:
///
///   `barInset`    where the drawn bar starts and ends
///   `travelInset` where the chip and the stops start and end
///
/// The chip is wider than the bar's rounded cap, so if the two matched, the
/// chip at either extreme would hang off the end of the bar. Running the bar
/// wider than the travel keeps the chip inside it horizontally while still
/// letting it overhang vertically — which is the whole look.
struct ArcSpec {
    /// -1 arcs the middle up, +1 sags it down.
    var bend: CGFloat = -1
    /// Rise from the bar's endpoints to its midpoint.
    ///
    /// Measured across the *bar*. Since the travel is inset from the bar's
    /// ends it only covers the middle of the parabola, so the arch actually
    /// read is shallower than this. Reference tab bars run 3–5% of their span.
    ///
    /// Measured off the Figma frame: the stops rise ~14.5pt from the outer
    /// pair to the middle one. Because the travel is inset from the bar's ends
    /// it only covers the middle of the parabola, so the bar's own depth has to
    /// be larger than that to leave 14.5 across the travelled part.
    var depth: CGFloat = 30
    /// Thickness of the bar. Figma frame measures ~70.
    var track: CGFloat = 70
    /// Where the curve's endpoints sit.
    ///
    /// NOT where the bar visually ends: the rounded cap extends `track / 2`
    /// past this, so anything below that puts the bar off-screen. For a bar
    /// that reaches ~2pt from each edge of a 393pt screen with a 70pt track,
    /// the endpoints have to start 37 in.
    var barInset: CGFloat = 37
    /// Leaves ~67pt between stops on a 393pt-wide screen, as in the Figma frame.
    var travelInset: CGFloat = 62
}

/// `ArcSpec` resolved against a concrete width and chip height.
struct ArcGeometry {
    let spec: ArcSpec
    let width: CGFloat
    /// Height of the bar's endpoints within the box.
    let yEnds: CGFloat
    /// Total height of the box.
    let height: CGFloat

    /// Vertical breathing room above and below whatever reaches furthest.
    static let padV: CGFloat = 14

    /// How far the furthest of bar and chip reaches from the curve.
    ///
    /// The chip may be the taller of the two, and it grows while pressed, so
    /// both are accounted for or the box clips at the extremes.
    static func reach(spec: ArcSpec, chipHeight: CGFloat) -> CGFloat {
        max(spec.track, chipHeight * PRESS_SCALE) / 2
    }

    /// Box height, which depends only on the shape and the chip — not on width.
    /// Named apart from the stored `height` so a call site cannot be misread.
    static func boxHeight(spec: ArcSpec, chipHeight: CGFloat) -> CGFloat {
        padV * 2 + spec.depth + reach(spec: spec, chipHeight: chipHeight) * 2
    }

    /// The box is sized by whichever of bar or chip reaches further from the
    /// curve — the chip may be the taller of the two, and that overhang is
    /// what makes it read as riding proud of the bar.
    init(spec: ArcSpec, width: CGFloat, chipHeight: CGFloat) {
        self.spec = spec
        self.width = width
        // Same helper the frame height uses, so the two cannot drift apart.
        let reach = Self.reach(spec: spec, chipHeight: chipHeight)
        // An arch pushes its middle up, so its ends must start lower to stay
        // in the box; a sag is the mirror image.
        self.yEnds = Self.padV + reach + (spec.bend < 0 ? spec.depth : 0)
        self.height = Self.padV * 2 + spec.depth + reach * 2
    }

    /// Travel position `u` (0…1) → x.
    func x(at u: CGFloat) -> CGFloat {
        spec.travelInset + (width - spec.travelInset * 2) * u
    }

    /// Travel position `u` (0…1) → y, following the bar's own parabola.
    func y(at u: CGFloat) -> CGFloat {
        let barSpan = width - spec.barInset * 2
        guard barSpan > 0 else { return yEnds }
        // Re-express the travel position along the bar before evaluating, so
        // stops sit on the drawn centreline rather than on a curve of their own.
        let t = (x(at: u) - spec.barInset) / barSpan
        return yEnds + spec.bend * 4 * spec.depth * t * (1 - t)
    }

    func point(at u: CGFloat) -> CGPoint { CGPoint(x: x(at: u), y: y(at: u)) }

    /// Finger x → travel position `u`, clamped to the ends of the travel.
    func u(atX px: CGFloat) -> CGFloat {
        let span = width - spec.travelInset * 2
        guard span > 0 else { return 0 }
        return min(1, max(0, (px - spec.travelInset) / span))
    }
}

/// The bar as a fillable outline, so Liquid Glass can be clipped to it.
///
/// A stroked path would be simpler but `glassEffect(in:)` needs a `Shape`, so
/// the outline is built explicitly: the curve offset up and down by half the
/// track, closed with semicircular caps.
///
/// Offsetting vertically rather than along the normal makes the band's
/// thickness vary with slope — but the arch is shallow enough that the worst
/// case (at the endpoints, where slope peaks) costs under 3% of the thickness,
/// which is invisible and buys a genuinely exact Bézier on both edges.
struct ArcBarShape: Shape {
    let geo: ArcGeometry

    func path(in rect: CGRect) -> Path {
        let r = geo.spec.track / 2
        let x0 = geo.spec.barInset
        let x1 = geo.width - geo.spec.barInset
        let midX = (x0 + x1) / 2
        // A quadratic reaches only halfway to its control point, so the
        // control sits at twice the depth to land the midpoint exactly on it.
        let ctrlY = geo.yEnds + geo.spec.bend * geo.spec.depth * 2

        var p = Path()
        p.move(to: CGPoint(x: x0, y: geo.yEnds - r))
        p.addQuadCurve(to: CGPoint(x: x1, y: geo.yEnds - r),
                       control: CGPoint(x: midX, y: ctrlY - r))
        // Right cap: sweeping through +x, which is increasing angle in
        // SwiftUI's y-down space.
        p.addArc(center: CGPoint(x: x1, y: geo.yEnds), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: x0, y: geo.yEnds + r),
                       control: CGPoint(x: midX, y: ctrlY + r))
        // Left cap: sweeping through -x.
        p.addArc(center: CGPoint(x: x0, y: geo.yEnds), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
