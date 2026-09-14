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
    /// invisible up close. The system effect, for its part, always casts a
    /// shadow, and this layer has none. Flat is what the file looks like at
    /// this size.
    static let barFill = Color(hex: 0xE9EDF4).opacity(0.60)

    // MARK: - Selected chip — layer "Switch Toggle Items [1.0]"
    //
    // The chip is the system's Liquid Glass (`glassEffect`, iOS 26), which is
    // what the file's Glass effect is a mockup *of*. Its rim, its refraction
    // of whatever passes beneath it, its response to touch and its shadow are
    // all the system's own; none of it is drawn here. The file's Glass
    // settings (Light −45°/80%, Refraction 80, Depth 21.7, Dispersion 50,
    // Frost 4.34) and its drop shadow (Y 5.42, Blur 10.85, #1B1C1D @ 5%) are
    // the designer's approximation of that effect and are not applied on top
    // of it — doubling the shadow was tried, and looked like it.

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

    // MARK: - Icons

    /// From the chip's "Selection colors" swatch.
    static let iconInk = Color(hex: 0x222222)

    /// Unselected stops' icons, measured: 26.11, 24.84, 25.09, 26.33 — so they
    /// are *larger* than the resting chip's icon, not smaller.
    static let stopIconSize: CGFloat = 25.6
}

/// The lit edge of Figma's Glass, laid over the system effect.
///
/// Liquid Glass derives its rim from whatever sits behind it. Behind the
/// chip and the Continue button is a near-white page, so it draws almost
/// none and both read as flat white capsules — while in the file each has a
/// clear bright edge from its light at −45°. This adds exactly that edge and
/// nothing else: a 1pt rim brightest at the top-left, plus a faint sheen in
/// the same corner. The glass underneath keeps doing the refraction, the
/// swell and the shadow.
///
/// Both surfaces are capsules, so the rim is a capsule too.
struct FigmaGlassEdge: ViewModifier {
    /// Figma: Light −45° / 80%.
    private let lit: UnitPoint = .topLeading
    private let shaded: UnitPoint = .bottomTrailing

    func body(content: Content) -> some View {
        content
            .overlay {
                Capsule()
                    .fill(LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.22), location: 0.0),
                            .init(color: .white.opacity(0.0), location: 0.55),
                        ],
                        startPoint: lit, endPoint: shaded
                    ))
                    .allowsHitTesting(false)
            }
            .overlay {
                Capsule()
                    .strokeBorder(LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.95), location: 0.0),
                            .init(color: .white.opacity(0.30), location: 0.45),
                            .init(color: .white.opacity(0.60), location: 1.0),
                        ],
                        startPoint: lit, endPoint: shaded
                    ), lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    /// See `FigmaGlassEdge`.
    func figmaGlassEdge() -> some View { modifier(FigmaGlassEdge()) }
}
