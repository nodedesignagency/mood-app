import SwiftUI

/// Where the bar and its stops sit, transcribed from the Figma file.
///
/// Node 1:330 ("Frame 2147239328") is 383 × 88.108 at (5, 744) on a 393 × 852
/// screen. Two different things are measured out of it, and they are *not* the
/// same curve:
///
///   `ArcBarShape`   the bar's own outline, node 1:331 ("Ellipse 4271")
///   `stops`         the five icon centres, hand-placed by the designer
///
/// Every earlier version drew the bar by stroking a curve fitted through the
/// stops. The stops are not on the bar's centreline — stop 0 sits 6.15pt below
/// it — so that fit came out the wrong shape *and* 9pt too thick (67.4 against
/// the real 58.5). The bar now comes from its own path and the stops from
/// their own measurements, which is the only way both can be right at once.
enum BarLayout {
    static let designWidth: CGFloat = 393
    static let frameWidth: CGFloat = 383
    static let frameHeight: CGFloat = 88.108
    /// Gap between the bar frame and each screen edge.
    static let sideInset: CGFloat = (designWidth - frameWidth) / 2

    /// Stop centres, in the bar frame's own coordinates.
    ///
    /// Unevenly spaced (gaps of 63.6, 74.5, 72.7, 66.0) and not symmetric
    /// top to bottom (54.89 at the left end against 48.84 at the right).
    /// That is the designer's hand, not noise, so it is preserved exactly.
    static let stops: [CGPoint] = [
        CGPoint(x: 52.89, y: 54.89),
        CGPoint(x: 116.47, y: 41.90),
        CGPoint(x: 190.96, y: 34.18),
        CGPoint(x: 263.65, y: 39.36),
        CGPoint(x: 329.64, y: 48.84),
    ]

    static let last = stops.count - 1
}

/// `BarLayout` resolved against a concrete width.
struct ArcGeometry {
    let width: CGFloat
    /// Horizontal scale, for screens wider or narrower than the design's 393.
    let scale: CGFloat

    var height: CGFloat { BarLayout.frameHeight }

    init(width: CGFloat) {
        self.width = width
        let usable = width - BarLayout.sideInset * 2
        self.scale = usable > 0 ? usable / BarLayout.frameWidth : 1
    }

    /// A point in the Figma frame's coordinates → this view's coordinates.
    ///
    /// Only x is scaled. Stretching y as well would thin the bar and flatten
    /// its caps on a narrow screen; leaving it alone keeps the band a constant
    /// 58.5pt everywhere and lets the arc shallow out instead, which is the
    /// failure mode you would choose.
    func map(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: BarLayout.sideInset + x * scale, y: y)
    }

    /// Position at a continuous stop index (0…4), on the spline through the
    /// measured stop centres.
    ///
    /// This is deliberately the stop curve and not the bar's centreline: when
    /// the chip settles it must land exactly where the designer put that icon,
    /// even where the two curves diverge.
    func point(at index: Double) -> CGPoint {
        map(
            Self.spline(BarLayout.stops.map(\.x), at: index),
            Self.spline(BarLayout.stops.map(\.y), at: index)
        )
    }

    /// Direction of travel at a continuous stop index, as a rotation to apply
    /// to something riding the curve so it lies along it rather than level.
    ///
    /// Read off `point(at:)` by central difference rather than by
    /// differentiating the spline: one function is the source of truth for
    /// where things are, and the angle is whatever that function implies.
    /// Positive is clockwise on screen (y grows downward), which is also what
    /// `rotationEffect` takes, so this needs no conversion. Works out at
    /// −11.6° on the far left, rising to +8.2° on the far right.
    func angle(at index: Double) -> Angle {
        let eps = 0.01
        let a = point(at: max(0, index - eps))
        let b = point(at: min(Double(BarLayout.last), index + eps))
        return .radians(atan2(b.y - a.y, b.x - a.x))
    }

    /// Finger x → continuous stop index.
    ///
    /// The stops are unevenly spaced, so this walks the measured x values and
    /// interpolates within the segment the finger is in, rather than dividing
    /// the width into equal parts.
    func index(atX px: CGFloat) -> Double {
        let local = (px - BarLayout.sideInset) / scale
        let xs = BarLayout.stops.map(\.x)
        if local <= xs.first! { return 0 }
        if local >= xs.last! { return Double(BarLayout.last) }
        for i in 0..<BarLayout.last where local <= xs[i + 1] {
            let span = xs[i + 1] - xs[i]
            return Double(i) + Double(span > 0 ? (local - xs[i]) / span : 0)
        }
        return Double(BarLayout.last)
    }

    /// Catmull-Rom through the control points: passes exactly through each one,
    /// stays smooth across segments, and extrapolates sensibly past the ends.
    private static func spline(_ values: [CGFloat], at t: Double) -> CGFloat {
        let last = values.count - 1
        let i = max(0, min(last - 1, Int(t.rounded(.down))))
        let u = CGFloat(t - Double(i))
        func at(_ k: Int) -> CGFloat { values[max(0, min(last, k))] }
        let p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2)
        return 0.5 * ((2 * p1)
            + (-p0 + p2) * u
            + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u
            + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u)
    }
}

/// The bar's outline, transcribed from Figma's `Ellipse 4271`.
///
/// Seven cubic segments, copied off the exported path rather than derived from
/// anything. They describe a band of constant 58.52pt thickness whose
/// centreline runs from (41.05, 51.32) to (342.61, 51.82) and rises to 34.34
/// at the middle — a 17pt rise over a 301.6pt span, about 5.6%. Nothing here
/// needs to know that; it is recorded because it is the check that these
/// numbers really are an arc with round caps, and it is what to re-measure
/// against if the design moves.
///
/// Reading the path: it opens at the right cap, runs the *top* edge right to
/// left, rounds the left cap, runs the *bottom* edge back left to right, and
/// closes through the right cap.
struct ArcBarShape: Shape {
    let geo: ArcGeometry

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: geo.map(370.929, 59.0768))
        // Right cap, upper half.
        p.addCurve(to: geo.map(350.499, 23.6375),
                   control1: geo.map(375.281, 43.5294),
                   control2: geo.map(366.215, 27.3343))
        // Top edge.
        p.addCurve(to: geo.map(33.2586, 23.1123),
                   control1: geo.map(246.199, -0.89632),
                   control2: geo.map(137.639, -1.07601))
        // Left cap.
        p.addCurve(to: geo.map(12.7114, 58.4838),
                   control1: geo.map(17.5304, 26.7571),
                   control2: geo.map(8.41111, 42.922))
        p.addCurve(to: geo.map(48.8445, 79.5208),
                   control1: geo.map(17.0117, 74.0455),
                   control2: geo.map(33.1024, 83.1052))
        // Bottom edge.
        p.addCurve(to: geo.map(334.726, 79.9941),
                   control1: geo.map(142.949, 58.0935),
                   control2: geo.map(240.694, 58.2554))
        // Right cap, lower half.
        p.addCurve(to: geo.map(370.929, 59.0768),
                   control1: geo.map(350.456, 83.6307),
                   control2: geo.map(366.577, 74.6242))
        p.closeSubpath()
        return p
    }
}
