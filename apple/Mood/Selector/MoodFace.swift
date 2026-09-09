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

struct MoodFace: View {
    /// Continuous mood position, 0…4.
    var progress: Double
    var size: CGFloat
    var color: Color

    private let eyeCX: CGFloat = 34
    private let eyeCY: CGFloat = 40
    private let eyeRX: CGFloat = 8.5
    private let mouthY: CGFloat = 64

    var body: some View {
        let t = FaceTraits.at(progress)
        let k = size / 100

        Canvas { ctx, _ in
            for cx in [eyeCX, 100 - eyeCX] {
                let rect = CGRect(x: (cx - eyeRX) * k, y: (eyeCY - t.eyeRY) * k,
                                  width: eyeRX * 2 * k, height: t.eyeRY * 2 * k)
                ctx.fill(Path(ellipseIn: rect), with: .color(color))
            }
            var mouth = Path()
            mouth.move(to: CGPoint(x: (50 - t.half) * k, y: mouthY * k))
            mouth.addQuadCurve(to: CGPoint(x: (50 + t.half) * k, y: mouthY * k),
                               control: CGPoint(x: 50 * k, y: (mouthY + t.curve) * k))
            ctx.stroke(mouth, with: .color(color),
                       style: StrokeStyle(lineWidth: 8 * k, lineCap: .round))
        }
        .frame(width: size, height: size)
        // Canvas is redrawn per frame while dragging; without this it is also
        // re-rasterised at unchanged scale, which is wasted work.
        .drawingGroup()
    }
}
