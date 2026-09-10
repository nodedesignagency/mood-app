import SwiftUI

/// Where the bar and its stops sit, measured from the Figma file rather than
/// derived from a formula.
///
/// Node 1:330 ("Frame 2147239328") is 383 × 88.108 at (5, 744) on a 393 × 852
/// screen, and the five stops inside it are hand-placed:
///
///     gaps between stops   63.6, 74.5, 72.7, 66.0     — not evenly spaced
///     y of each stop       54.9, 41.9, 34.2, 39.4, 48.8
///     left end vs right    54.9 vs 48.8               — not symmetric
///
/// Every earlier version fitted a symmetric quadratic through these. A
/// symmetric curve cannot represent an asymmetric arc, so it missed each stop
/// by several points and no amount of tuning its depth or inset could close
/// the gap. The measured points are the source of truth now, with a spline
/// running through them.
enum BarLayout {
    static let designWidth: CGFloat = 393
    static let frameWidth: CGFloat = 383
    static let frameHeight: CGFloat = 88.108
    /// Gap between the bar and each screen edge.
    static let sideInset: CGFloat = (designWidth - frameWidth) / 2

    /// Stop centres, in the bar frame's own coordinates.
    static let stops: [CGPoint] = [
        CGPoint(x: 52.89, y: 54.89),
        CGPoint(x: 116.47, y: 41.90),
        CGPoint(x: 190.96, y: 34.18),
        CGPoint(x: 263.65, y: 39.36),
        CGPoint(x: 329.64, y: 48.84),
    ]

    /// Bar thickness.
    ///
    /// The frame is 88.108 tall and the curve's own y spans 20.71 of that,
    /// which leaves 67.4 — so a band of that width centred on the curve fills
    /// the frame exactly, top and bottom. That the numbers land this neatly is
    /// the check that the bar really is a constant-thickness arc.
    static let track: CGFloat = 88.108 - (54.89 - 34.18)

    /// How far past the outer stops the bar reaches, in stop-index units.
    ///
    /// The stops span 52.89…329.64 but the bar spans the full 383, so its ends
    /// carry on past them. 0.30 of a step puts the round caps on the frame's
    /// left and right edges.
    static let overhang: Double = 0.30

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

    /// Position at a continuous stop index (0…4), on the spline through the
    /// measured points. Values outside that range extrapolate along the end
    /// tangents, which is what draws the bar past its outer stops.
    func point(at index: Double) -> CGPoint {
        CGPoint(
            x: BarLayout.sideInset + Self.spline(BarLayout.stops.map(\.x), at: index) * scale,
            y: Self.spline(BarLayout.stops.map(\.y), at: index)
        )
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

/// The bar as a fillable outline.
///
/// The spline is sampled, offset up and down by half the track, and closed
/// with semicircular caps — the same construction as stroking it, but as a
/// `Shape` so it can be filled, gradient-stroked and clipped.
struct ArcBarShape: Shape {
    let geo: ArcGeometry
    /// Samples along the curve. Enough that the offset edges read as smooth.
    private let steps = 48

    func path(in rect: CGRect) -> Path {
        let r = BarLayout.track / 2
        let from = -BarLayout.overhang
        let to = Double(BarLayout.last) + BarLayout.overhang

        func sample(_ k: Int) -> CGPoint {
            geo.point(at: from + (to - from) * Double(k) / Double(steps))
        }

        let start = sample(0)
        let end = sample(steps)

        var p = Path()
        p.move(to: CGPoint(x: start.x, y: start.y - r))
        for k in 1...steps {
            let s = sample(k)
            p.addLine(to: CGPoint(x: s.x, y: s.y - r))
        }
        // Right cap: through +x, which is increasing angle in y-down space.
        p.addArc(center: end, radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        for k in stride(from: steps - 1, through: 0, by: -1) {
            let s = sample(k)
            p.addLine(to: CGPoint(x: s.x, y: s.y + r))
        }
        // Left cap: through -x.
        p.addArc(center: start, radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
