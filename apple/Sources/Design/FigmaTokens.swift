import SwiftUI

/// Values transcribed from the Figma file, kept together so they stay
/// traceable to their source layer rather than scattered as magic numbers.
///
/// Layer names are the ones in the Figma document, so a value can be checked
/// against the design without hunting for it.
enum Figma {

    // MARK: - App background

    /// The app's base colour.
    static let background = Color(hex: 0xF8F9FC)

    // MARK: - Bar — layer "Ellipse 4271"

    static let barFill = Color(hex: 0xE9EDF4).opacity(0.60)

    // MARK: - Selected chip — layer "Switch Toggle Items [1.0]"

    static let chipSize = CGSize(width: 78.12, height: 48.42)
    /// Corner radius reads 1083.9 in Figma, which is its way of saying
    /// "fully rounded". A capsule is the same thing without the magic number.
    static var chipCornerRadius: CGFloat { chipSize.height / 2 }
    static let chipFill = Color.white.opacity(0.65)
    static let chipPaddingH: CGFloat = 17.36
    static let chipPaddingV: CGFloat = 13.02

    /// Drop shadow: X 0, Y 5.42, Blur 10.85, Spread 0, #1B1C1D @ 5%.
    ///
    /// Figma's "Blur" is roughly twice the Gaussian sigma, while SwiftUI's
    /// `radius` is roughly the sigma itself — so the blur is halved on the way
    /// across, otherwise the shadow comes out twice as soft as designed.
    static let chipShadowColor = Color(hex: 0x1B1C1D).opacity(0.05)
    static let chipShadowRadius: CGFloat = 10.85 / 2
    static let chipShadowY: CGFloat = 5.42

    // MARK: - Icons

    /// From the chip's "Selection colors" swatch.
    static let iconInk = Color(hex: 0x222222)
    /// The selected chip's icon, measured: 22.376 in the file.
    static let chipIconSize: CGFloat = 22.38

    /// Unselected stops' icons, measured: 26.11, 24.84, 25.09, 26.33 — so they
    /// are *larger* than the selected one, not smaller.
    static let stopIconSize: CGFloat = 25.6

    // MARK: - Glass
    //
    // Figma's Glass effect and SwiftUI's `glassEffect` are not the same thing.
    //
    // `glassEffect` refracts whatever sits behind it. Behind these surfaces is
    // a near-white bar on an F8F9FC background — there is nothing to refract,
    // so it renders as near-white and the surface reads as flat. That is the
    // modifier working correctly, not a tuning problem.
    //
    // Figma's Glass is a stylistic shader: Refraction and Depth draw a lit rim
    // and an inner bevel regardless of the backdrop. So that look is drawn
    // explicitly below, from the values in the file:
    //
    //   bar   Light 162°/80%, Refraction 100, Depth 37.97, Dispersion 0,
    //         Frost 0, Splay 0
    //   chip  Light −45°/80%, Refraction 80,  Depth 21.7,  Dispersion 50,
    //         Frost 4.34, Splay 0
    //
    // Depth maps to rim width and bevel strength; the light angle maps to which
    // edge is lit. Dispersion (a chromatic fringe) and Splay have no cheap
    // equivalent and are left out.

    /// Colour the unlit edge is shaded with — the shadow colour from the file.
    static let rimShade = Color(hex: 0x1B1C1D)

    /// Rim width, scaled from each surface's Depth.
    static let barRimWidth: CGFloat = 2
    static let chipRimWidth: CGFloat = 1.5
}

/// The gradient pair that stands in for one Figma Glass effect.
///
/// `lit` is the corner the light comes from, taken from Figma's light angle;
/// the bevel runs from there to the opposite corner, bright through neutral to
/// a faint shade.
struct GlassBevel {
    var lit: UnitPoint
    var shaded: UnitPoint
    var rimWidth: CGFloat
    /// 0–1, from Figma's light strength.
    var strength: Double

    /// Bar — Light 162°, Depth 37.97. Lit along its upper edge.
    static let bar = GlassBevel(lit: .top, shaded: .bottom,
                                rimWidth: Figma.barRimWidth, strength: 0.8)
    /// Chip — Light −45°, Depth 21.7. Lit from the upper left.
    static let chip = GlassBevel(lit: .topLeading, shaded: .bottomTrailing,
                                 rimWidth: Figma.chipRimWidth, strength: 0.8)

    /// Bright where the light lands, fading to a faint shade opposite.
    var rim: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.98 * strength), location: 0),
                .init(color: .white.opacity(0.38 * strength), location: 0.30),
                .init(color: .clear, location: 0.60),
                .init(color: Figma.rimShade.opacity(0.14 * strength), location: 1),
            ],
            startPoint: lit, endPoint: shaded
        )
    }

    /// Inner sheen — the bevel catching light across the lit half.
    var sheen: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.62 * strength), location: 0),
                .init(color: .white.opacity(0.14 * strength), location: 0.40),
                .init(color: .clear, location: 0.72),
            ],
            startPoint: lit, endPoint: shaded
        )
    }
}
