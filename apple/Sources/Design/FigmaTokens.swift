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

    /// The layer's entire paint: `fill="#E9EDF4" fill-opacity="0.6"`.
    ///
    /// Worth stating plainly, because it is the thing that kept getting added
    /// to: in the exported SVG this layer carries one flat fill and no filter.
    /// No shadow, no rim, no bevel. Everything else you see on the bar in the
    /// design is the Glass effect, which the system now draws (see below).
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
    /// This is the *only* shadow in the bar — it belongs to the chip and
    /// nothing else. The export agrees: one `filter` in the whole SVG, on this
    /// layer, its region grown by 10.85 and offset 5.42 down.
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
    // Both surfaces use the system's Liquid Glass — `glassEffect(_:in:)`,
    // iOS 26 — rather than gradients pretending to be it.
    //
    // An earlier pass concluded the modifier "renders flat here" and replaced
    // it with a hand-drawn rim and bevel. The reasoning was that glass
    // refracts its backdrop and the backdrop here is near-white, so there is
    // nothing to refract. That much is true, but the conclusion did not
    // follow: `.regular` draws its own specular rim and highlight whatever
    // sits behind it, which is the part of the look that was missing. The
    // imitation, meanwhile, ended in a dark `rimShade` stroke along the
    // bottom edge — and *that* is what read as a drop shadow the design
    // never asked for.
    //
    // How the file's Glass settings map onto the modifier:
    //
    //   bar   Light 162°/80%, Refraction 100, Depth 37.97, Dispersion 0,
    //         Frost 0, Splay 0
    //   chip  Light −45°/80%, Refraction 80,  Depth 21.7,  Dispersion 50,
    //         Frost 4.34, Splay 0
    //
    // Light angle, refraction and depth are all things `.regular` decides for
    // itself from the shape and the ambient environment — there is no knob for
    // them and there does not need to be. What does carry across is each
    // layer's fill, which becomes the glass tint: `barFill` and `chipFill`
    // above. Dispersion and Splay have no equivalent and are left out.
}
