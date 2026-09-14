import SwiftUI

/// 光学与折射模式
public enum LiquidGlassRefractionMode: Float, CaseIterable, Sendable {
    /// 防撕裂单调放大：保持文字可读，边缘平滑放大与流光色散，适合导航栏、按钮、TabBar
    case foldFree = 0.0

    /// 真实物理倒像：大曲率厚透镜，UV折叠，文字颠倒翻转、图标分裂裂变
    case opticalInversion = 1.0
}

/// 几何形状规范
public enum LiquidGlassShapeStyle: Sendable {
    /// 胶囊形（两端全圆角）
    case capsule
    /// iOS 连续曲率圆角矩形（Squircle，p-norm ~4.2）
    case squircle(radius: CGFloat)
    /// 经典标准圆角
    case roundedRectangle(radius: CGFloat)
    /// 正圆（玻璃珠）
    case circle
}

/// 通用液态玻璃透镜的核心参数配置
public struct LiquidGlassConfiguration: Equatable, Sendable {
    /// 边缘折射倒角宽度（像素/点）。决定透镜边缘弯曲带的宽度。
    public var bezel: CGFloat

    /// 折射/形变位移强度。越大位移越强。
    public var strength: CGFloat

    /// 折射模式：单调防撕裂 vs 真实物理倒像
    public var mode: LiquidGlassRefractionMode

    /// 6波段连续光谱色散强度（0.0 ~ 2.0）
    public var dispersion: CGFloat

    /// 边缘菲涅尔白色轮廓线亮度（外边缘清透立体白边高光）
    public var fresnelRim: CGFloat

    /// 边缘 Blinn-Phong 弧光高光强度
    public var specular: CGFloat

    /// 光源入射角度（弧度制，默认从左上方约 -45° 照下）
    public var lightAngle: CGFloat

    /// 圆角大小（-1 代表全胶囊）
    public var cornerRadius: CGFloat

    /// 连续曲率指数（2.0 = 标准圆，4.2 = iOS 平滑连续超椭圆）
    public var cornerExponent: CGFloat

    public init(
        bezel: CGFloat = 16.0,
        strength: CGFloat = 22.0,
        mode: LiquidGlassRefractionMode = .opticalInversion,
        dispersion: CGFloat = 0.85,
        fresnelRim: CGFloat = 0.65,
        specular: CGFloat = 0.45,
        lightAngle: CGFloat = -0.785,
        shape: LiquidGlassShapeStyle = .squircle(radius: 24.0)
    ) {
        self.bezel = bezel
        self.strength = strength
        self.mode = mode
        self.dispersion = dispersion
        self.fresnelRim = fresnelRim
        self.specular = specular
        self.lightAngle = lightAngle

        switch shape {
        case .capsule:
            self.cornerRadius = -1.0
            self.cornerExponent = 2.0
        case .squircle(let r):
            self.cornerRadius = r
            self.cornerExponent = 4.2
        case .roundedRectangle(let r):
            self.cornerRadius = r
            self.cornerExponent = 2.0
        case .circle:
            self.cornerRadius = -1.0
            self.cornerExponent = 2.0
        }
    }

    // MARK: - 经典场景预设

    /// 【物理透镜 / 桌面放大镜】真实凸透镜倒像：UV 折叠颠倒、厚透镜菲涅尔立体亮边，适合桌面全局镜片或物理透镜组件
    public static var opticalInversionPreset: LiquidGlassConfiguration {
        LiquidGlassConfiguration(
            bezel: 18.0,
            strength: 28.0,
            mode: .opticalInversion,
            dispersion: 0.95,
            fresnelRim: 0.85,
            specular: 0.55,
            shape: .squircle(radius: 28.0)
        )
    }

    /// 【UI 控件 / TabBar / 按钮】防撕裂单调放大：文字完全清晰、边缘微变形、6 色流光，适合导航栏、按钮、控制条
    public static var foldFreePreset: LiquidGlassConfiguration {
        LiquidGlassConfiguration(
            bezel: 14.0,
            strength: 15.0,
            mode: .foldFree,
            dispersion: 0.65,
            fresnelRim: 0.45,
            specular: 0.35,
            shape: .capsule
        )
    }

    /// 【App 卡片容器】高级液态玻璃卡片预设：平滑超椭圆边缘、晶莹透光、适度菲涅尔微光
    public static var cardPreset: LiquidGlassConfiguration {
        LiquidGlassConfiguration(
            bezel: 16.0,
            strength: 18.0,
            mode: .foldFree,
            dispersion: 0.70,
            fresnelRim: 0.60,
            specular: 0.40,
            shape: .squircle(radius: 24.0)
        )
    }

    /// 【水晶水滴】清透大水滴感，高菲涅尔光、柔和色散
    public static var crystalWaterPreset: LiquidGlassConfiguration {
        LiquidGlassConfiguration(
            bezel: 22.0,
            strength: 32.0,
            mode: .opticalInversion,
            dispersion: 0.50,
            fresnelRim: 0.90,
            specular: 0.70,
            shape: .squircle(radius: 36.0)
        )
    }
}
