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
    // Figma's Glass and SwiftUI's `glassEffect` share a name and do opposite
    // things, so this is drawn by hand — see `FigmaGlass` below for the how
    // and the why.

    /// Rim width, scaled from each surface's Figma Depth.
    ///
    /// Depth is the thickness of the glass slab. There is no published formula
    /// from slab depth to the width of the refracted band you see face-on, so
    /// this divisor is fitted by eye against the Figma render. What it does
    /// preserve is the *ratio* between the two surfaces — 37.97 / 21.7 = 1.75,
    /// and 3.0 / 1.7 = 1.76 — so the bar reads as the thicker glass of the two,
    /// which is the part that carries the look.
    static let depthToRim: CGFloat = 12.7
}

/// Figma's Glass effect, drawn explicitly.
///
/// ## Why not `glassEffect`
///
/// Apple's Liquid Glass samples the pixels behind a view and refracts them.
/// Behind this bar is a flat #F8F9FC page, and refracting a flat colour
/// returns the same flat colour — there is nothing to bend, so nothing shows.
/// It also always draws an elevation shadow, and the whole `Glass` type is
/// `.regular` / `.clear` / `.identity` plus `tint` and `interactive`: there is
/// no knob to turn that off. The bar in the file has no shadow, so the system
/// effect cannot match it. Not a tuning problem — the wrong tool.
///
/// Figma's Glass is a stylistic shader instead: Refraction and Depth draw a
/// lens ring and an inner bevel from the shape's own outline, which is why it
/// reads as glass on a blank canvas. That is what is reproduced here.
///
/// ## The two rules that matter
///
/// An earlier attempt at this produced the shadow it was meant to avoid, for
/// two reasons worth stating so they are not repeated:
///
/// 1. **Everything stays inside the shape.** It used `stroke`, which centres
///    the line on the outline and leaves half of it outside. Outside the
///    silhouette is where shadows live. Strokes here are drawn at twice the
///    width and clipped back to the shape, which leaves exactly the inner
///    half — or `strokeBorder`, where the shape is insettable.
///
/// 2. **Nothing is darker than the fill.** It ended its rim in #1B1C1D at 14%
///    along the bottom edge, which is a drop shadow with extra steps. A thick
///    glass slab on a light ground scatters light out through its edges, so
///    they go *brighter* than the body, never darker. Every stop below is
///    white.
struct FigmaGlass {
    /// The corner the light comes from, from Figma's light angle.
    var lit: UnitPoint
    /// The opposite corner. The bevel runs between the two.
    var shaded: UnitPoint
    /// Figma's Depth for this surface.
    var depth: CGFloat
    /// 0–1, from Figma's light strength.
    var strength: Double

    var rimWidth: CGFloat { depth / Figma.depthToRim }

    /// Bar — Light 162°, Depth 37.97, Refraction 100, Frost 0, Dispersion 0.
    /// Lit along its upper edge.
    static let bar = FigmaGlass(lit: .top, shaded: .bottom, depth: 37.97, strength: 0.8)

    /// Chip — Light −45°, Depth 21.7, Refraction 80, Frost 4.34, Dispersion 50.
    /// Lit from the upper left.
    ///
    /// Frost is a backdrop blur; behind the chip is the bar, which is itself
    /// near-flat, so blurring it would change almost nothing and is left out.
    /// Dispersion is a chromatic fringe with no cheap equivalent, also left out.
    static let chip = FigmaGlass(lit: .topLeading, shaded: .bottomTrailing, depth: 21.7, strength: 0.8)

    /// The lit edge, hugging the inside of the outline.
    ///
    /// Bright where the light lands, falling away, then lifting again at the
    /// far edge — light that entered the slab leaving through the opposite
    /// side. That second lift is what separates thick glass from a painted
    /// highlight, and it is why the bar gets a wider rim than the chip.
    var rim: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.95 * strength), location: 0.00),
                .init(color: .white.opacity(0.55 * strength), location: 0.28),
                .init(color: .white.opacity(0.18 * strength), location: 0.62),
                .init(color: .white.opacity(0.45 * strength), location: 1.00),
            ],
            startPoint: lit, endPoint: shaded
        )
    }

    /// Inner sheen — the body of the slab catching light across its lit half.
    var sheen: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.40 * strength), location: 0.00),
                .init(color: .white.opacity(0.10 * strength), location: 0.42),
                .init(color: .clear, location: 0.78),
            ],
            startPoint: lit, endPoint: shaded
        )
    }
}
