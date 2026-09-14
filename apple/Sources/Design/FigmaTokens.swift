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

    /// The layer's paint: `fill="#E9EDF4" fill-opacity="0.6"`. Drawn flat.
    ///
    /// The file also puts a Glass effect on this layer, and it is deliberately
    /// not reproduced. The band is only ~10 levels off the page behind it, so
    /// any highlight bright enough to read merges with the background and
    /// eats the silhouette, and any dim enough to keep the silhouette is
    /// invisible up close. Flat is what the file looks like at this size.
    static let barFill = Color(hex: 0xE9EDF4).opacity(0.60)

    // MARK: - Glass
    //
    // Both glass surfaces are drawn by the vendored LiquidGlassKit shader
    // (Sources/Vendor), which refracts whatever is behind the lens and draws
    // the edge: a white Fresnel hairline, a specular arc on the lit side, and
    // a darkening on the shadow side. Those are the three things visible at
    // the edge of every glass layer in the file, and the reason the previous
    // attempts read as flat — Apple's own effect draws none of them over a
    // near-white page, and hand-painted gradients could not fake refraction.
    //
    // How the file's Glass panel maps onto the shader. The shader is a
    // vendored copy with its edge lighting rewritten (see the .metal header),
    // and every number here was checked in a NumPy port of it, rendered
    // against the Figma file — not guessed.
    //
    //   Depth       → bezel        × 0.645. The shader's band is wider than
    //                              Figma's for the same number; 21.7 straight
    //                              across washes the whole chip, 14 matches.
    //   Refraction  → strength     the shader saturates at 0.44 × bezel, so
    //                              Refraction% × 0.44 × bezel keeps the
    //                              slider meaningful
    //   Dispersion  → dispersion   50 → 0.5
    //   Light %     → fresnelRim   0.75: the 1.5pt hairline's brightness
    //   Light angle → lightAngle   see below
    //   (soft light)→ specular     0.14: the broad wash over the edge band
    //   Frost       → (none)       a backdrop blur the shader does not do
    //
    // Light angle. The file says −45° and shows the highlight top-left. In
    // the shader a surface is lit where its outward normal points *toward*
    // the light, i.e. where `dot(normal, −L)` is largest, with y down. A
    // source at the top-left means −L = (−1, −1)/√2, so L = (1, 1)/√2 and
    // the angle passed is atan2(1, 1) = +45° = +0.785 rad — the sign flips
    // on the way across. Confirmed in the port: +0.785 lights the top-left.

    private static let lightAngleTopLeft: CGFloat = 0.785

    /// Chip — layer "Switch Toggle Items [1.0]":
    /// Light −45°/80%, Refraction 80, Depth 21.7, Dispersion 50, Frost 4.34.
    static let chipGlass = LiquidGlassConfiguration(
        bezel: 21.7 * 0.645,
        strength: 0.80 * 0.44 * 21.7 * 0.645,
        mode: .foldFree,
        dispersion: 0.5,
        fresnelRim: 0.75,
        specular: 0.14,
        lightAngle: lightAngleTopLeft,
        shape: .capsule
    )

    /// Continue — layer "Frame 2147239336":
    /// Light −45°/80%, Refraction 80, Depth 25.45, Dispersion 50, Frost 5.09.
    static let buttonGlass = LiquidGlassConfiguration(
        bezel: 25.45 * 0.645,
        strength: 0.80 * 0.44 * 25.45 * 0.645,
        mode: .foldFree,
        dispersion: 0.5,
        fresnelRim: 0.75,
        specular: 0.14,
        lightAngle: lightAngleTopLeft,
        shape: .capsule
    )

    /// Drop shadow, identical on the chip and the button:
    /// X 0, Y 5.42, Blur 10.85, Spread 0, #1B1C1D @ 5%.
    ///
    /// Figma's "Blur" is roughly twice the Gaussian sigma, while SwiftUI's
    /// `radius` is roughly the sigma itself — so the blur is halved on the way
    /// across, otherwise the shadow comes out twice as soft as designed.
    static let shadowColor = Color(hex: 0x1B1C1D).opacity(0.05)
    static let shadowRadius: CGFloat = 10.85 / 2
    static let shadowY: CGFloat = 5.42

    // MARK: - Selected chip — layer "Switch Toggle Items [1.0]"

    /// Fill FFFFFF @ 65%.
    static let chipFill = Color.white.opacity(0.65)

    /// At rest — the "Active state" frame.
    static let chipSize = CGSize(width: 78.12, height: 48.42)
    /// The selected chip's icon, measured: 22.376 in the file.
    static let chipIconSize: CGFloat = 22.38

    /// Under a thumb — the "When pressed" frame, node 1:384.
    ///
    /// Not a uniform scale of the resting chip: 1.20× wide by 1.36× tall,
    /// with the icon at 1.53×. The centre stays put, so it grows in place.
    static let chipPressedSize = CGSize(width: 94, height: 66)
    static let chipPressedIconSize: CGFloat = 34.2

    // MARK: - Continue — layer "Frame 2147239336"

    /// Fill FFFFFF @ 70%. 128.45 × 49.45, gap 6, text 17pt.
    static let buttonFill = Color.white.opacity(0.70)
    static let buttonSize = CGSize(width: 128.45, height: 49.45)
    static let buttonGap: CGFloat = 6

    // MARK: - Icons

    /// From the chip's "Selection colors" swatch.
    static let iconInk = Color(hex: 0x222222)

    /// Unselected stops' icons, measured: 26.11, 24.84, 25.09, 26.33 — so they
    /// are *larger* than the resting chip's icon, not smaller.
    static let stopIconSize: CGFloat = 25.6
}
