import SwiftUI

/// A refracting lens over live content, on the vendored LiquidGlassKit shader,
/// with the lens's centre and size animatable.
///
/// The library's own `LiquidGlassCanvas` takes the lens frame as plain stored
/// values, and SwiftUI only interpolates what it is told is animatable — so a
/// lens driven that way *jumps* to each new position. Declaring the frame as
/// `animatableData` is what lets the chip slide under the thumb, spring onto
/// a stop, and swell on press with the refraction following it exactly.
///
/// Everything drawn inside `content` is what gets refracted; anything that
/// must stay crisp (the chip's own icon) goes on top, outside this modifier.
struct LensCanvas: ViewModifier, Animatable {
    var center: CGPoint
    var size: CGSize
    /// Rotation of the lens about its centre, clockwise-positive on screen.
    /// The lens rides a curve, so it has to lie along it or it pokes out of
    /// the bar at the ends.
    var rotation: Angle
    var config: LiquidGlassConfiguration

    var animatableData: AnimatablePair<AnimatablePair<CGPoint.AnimatableData, CGSize.AnimatableData>, Double> {
        get { AnimatablePair(AnimatablePair(center.animatableData, size.animatableData), rotation.radians) }
        set {
            center.animatableData = newValue.first.first
            size.animatableData = newValue.first.second
            rotation = .radians(newValue.second)
        }
    }

    func body(content: Content) -> some View {
        // Copied out so the effect closure captures values, not the modifier.
        let center = center
        let size = size
        let rotation = Float(rotation.radians)
        let config = config
        // How far the shader may sample outside a pixel: the largest
        // displacement, widened by dispersion, plus the edge band.
        let reach = config.strength * (1 + config.dispersion) + config.bezel

        return content.visualEffect { view, _ in
            view.layerEffect(
                ShaderLibrary.default.liquidGlassCanvas(
                    .float2(Float(center.x), Float(center.y)),
                    .float2(Float(size.width), Float(size.height)),
                    .float(rotation),
                    .float(Float(config.cornerRadius)),
                    .float(Float(config.cornerExponent)),
                    .float(Float(config.bezel)),
                    .float(Float(config.strength)),
                    .float(config.mode.rawValue),
                    .float(Float(config.dispersion)),
                    .float(Float(config.fresnelRim)),
                    .float(Float(config.specular)),
                    .float(Float(config.lightAngle))
                ),
                maxSampleOffset: CGSize(width: reach, height: reach)
            )
        }
    }
}

extension View {
    /// Refract this view through a lens of `size` centred at `center`, both
    /// in this view's own coordinates. See `LensCanvas`.
    func lensCanvas(center: CGPoint, size: CGSize, rotation: Angle, config: LiquidGlassConfiguration) -> some View {
        modifier(LensCanvas(center: center, size: size, rotation: rotation, config: config))
    }
}
