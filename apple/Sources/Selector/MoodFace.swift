import SwiftUI

/// The five expressions, drawn in a 100×100 space so one definition scales
/// from a small bar icon up to anything larger.
///
/// These are placeholders for your icon set — swap `MoodFace` for `Image(...)`
/// once the real assets land. Keeping them as code means the bar is complete
/// and testable before any asset exists.
struct FaceTraits {
    /// Vertical eye radius: wide open in the middle, squeezed at both extremes.
    static let eyeRY: [CGFloat] = [5, 7, 8.5, 8, 4]
    /// Mouth control-point offset. Negative frowns, positive grins.
    static let mouthCurve: [CGFloat] = [-16, -9, 1, 17, 32]
    /// Half the mouth's width — grins are wider than frowns.
    static let mouthHalf: [CGFloat] = [17, 18, 20, 22, 25]

    /// Interpolate the traits at a continuous position, so a face driven by the
    /// thumb morphs rather than cutting between five drawings.
    static func at(_ progress: Double) -> (eyeRY: CGFloat, curve: CGFloat, half: CGFloat) {
        let clamped = min(Double(eyeRY.count - 1), max(0, progress))
        let lower = Int(clamped)
        let upper = min(eyeRY.count - 1, lower + 1)
        let t = CGFloat(clamped - Double(lower))
        func lerp(_ a: [CGFloat]) -> CGFloat { a[lower] + (a[upper] - a[lower]) * t }
        return (lerp(eyeRY), lerp(mouthCurve), lerp(mouthHalf))
    }
}

/// The mouth: one quadratic whose control point sweeps frown → grin.
struct MouthShape: Shape {
    var half: CGFloat
    var curve: CGFloat

    func path(in rect: CGRect) -> Path {
        let k = rect.width / 100
        var p = Path()
        p.move(to: CGPoint(x: (50 - half) * k, y: MoodFace.mouthY * k))
        p.addQuadCurve(
            to: CGPoint(x: (50 + half) * k, y: MoodFace.mouthY * k),
            control: CGPoint(x: 50 * k, y: (MoodFace.mouthY + curve) * k)
        )
        return p
    }
}

/// A face at a continuous mood position.
///
/// Built from plain shapes rather than a `Canvas`. A Canvas wants
/// `drawingGroup()` to avoid re-rasterising every frame of a drag, and that
/// rasterises offscreen — which does not compose dependably when the face is
/// an overlay on a glass surface. Two ellipses and a stroked path cost
/// nothing and always draw.
struct MoodFace: View {
    /// Continuous mood position, 0…4.
    var progress: Double
    var size: CGFloat
    var color: Color

    /// Geometry in the shared 100×100 space.
    static let mouthY: CGFloat = 64
    private static let eyeOffsetX: CGFloat = 16
    private static let eyeOffsetY: CGFloat = -10
    private static let eyeWidth: CGFloat = 17

    var body: some View {
        let t = FaceTraits.at(progress)
        let k = size / 100

        ZStack {
            ForEach([CGFloat(-1), CGFloat(1)], id: \.self) { side in
                Ellipse()
                    .fill(color)
                    .frame(width: Self.eyeWidth * k, height: t.eyeRY * 2 * k)
                    .offset(x: Self.eyeOffsetX * k * side, y: Self.eyeOffsetY * k)
            }
            MouthShape(half: t.half, curve: t.curve)
                .stroke(color, style: StrokeStyle(lineWidth: 8 * k, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}
