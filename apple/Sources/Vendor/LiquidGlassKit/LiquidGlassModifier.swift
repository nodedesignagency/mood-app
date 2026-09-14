import SwiftUI

private let defaultShaderLibrary: ShaderLibrary = {
    #if SWIFT_PACKAGE
    if let url = Bundle.module.url(forResource: "default", withExtension: "metallib") {
        return ShaderLibrary(url: url)
    }
    #endif
    return .default
}()

public struct LiquidGlassLensModifier: ViewModifier {
    public var config: LiquidGlassConfiguration
    public var isEnabled: Bool

    public init(config: LiquidGlassConfiguration, isEnabled: Bool = true) {
        self.config = config
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        if isEnabled {
            content.visualEffect { view, geometry in
                let size = geometry.size
                let maxSampleOffset = config.strength * (1.0 + config.dispersion) + config.bezel

                return view.layerEffect(
                    defaultShaderLibrary.liquidGlassLens(
                        .float2(Float(size.width), Float(size.height)),
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
                    maxSampleOffset: CGSize(width: maxSampleOffset, height: maxSampleOffset),
                    isEnabled: true
                )
            }
        } else {
            content
        }
    }
}

public extension View {
    /// 为当前视图添加通用液态玻璃透镜折射效果
    ///
    /// - Parameters:
    ///   - config: 完整配置对象（包含预设 .opticalInversionPreset、.foldFreePreset 等）
    ///   - isEnabled: 是否启用
    func liquidGlassLens(
        _ config: LiquidGlassConfiguration = .opticalInversionPreset,
        isEnabled: Bool = true
    ) -> some View {
        self.modifier(LiquidGlassLensModifier(config: config, isEnabled: isEnabled))
    }

    /// 便捷方法：指定关键光学参数应用液态玻璃效果
    func liquidGlassLens(
        bezel: CGFloat = 18.0,
        strength: CGFloat = 28.0,
        mode: LiquidGlassRefractionMode = .opticalInversion,
        dispersion: CGFloat = 0.85,
        fresnelRim: CGFloat = 0.75,
        cornerRadius: CGFloat = 24.0,
        isEnabled: Bool = true
    ) -> some View {
        let config = LiquidGlassConfiguration(
            bezel: bezel,
            strength: strength,
            mode: mode,
            dispersion: dispersion,
            fresnelRim: fresnelRim,
            shape: .squircle(radius: cornerRadius)
        )
        return self.liquidGlassLens(config, isEnabled: isEnabled)
    }
}
