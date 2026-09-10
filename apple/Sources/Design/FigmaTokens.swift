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
    /// Chip height minus its vertical padding: 48.42 − (13.02 × 2).
    static var iconSize: CGFloat { chipSize.height - chipPaddingV * 2 }

    // MARK: - Glass
    //
    // Figma exposes Refraction / Depth / Dispersion / Frost / Splay. SwiftUI's
    // `glassEffect` exposes none of them — it has a variant, a tint and an
    // interactive flag, and the system decides the optics. So these are
    // recorded for reference, not applied:
    //
    //   bar   Light 162°/80%, Refraction 100, Depth 37.97, Dispersion 0,
    //         Frost 0, Splay 0
    //   chip  Light −45°/80%, Refraction 80,  Depth 21.7,  Dispersion 50,
    //         Frost 4.34, Splay 0
    //
    // Both read as clear rather than frosted (Frost ≈ 0), but `.clear` on a
    // near-white background all but vanishes, so both use `.regular` and lean
    // on the Figma fill colours underneath to carry the tone.
}
