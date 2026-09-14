#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MODIFIED FROM UPSTREAM (sqoder/LiquidGlassKit) — see Vendor/LiquidGlassKit/README.md
//
// Upstream draws its edge for dark glass over photos: a 3.5pt-wide Fresnel
// band and a tight pow-18 specular blob. Over a near-white page that reads as
// a fat white ring with a hot spot. The design's glass edge is a ~1px rim, a
// broad soft light on the lit side, and a faint darkening on the far side.
// Both shader functions below draw that instead, in the same parameter slots:
//
//   fresnel   brightness of a 1.5pt hairline (was: of a 3.5pt band)
//   specular  amount of broad soft light over the edge band (was: blob)
//   counter-rim darkening 0.10 · edge², quadratic (was: 0.14 · edge)
//
// The refraction, tangential shear and 6-tap dispersion are unchanged. The
// numbers were tuned in a NumPy port of this function against the Figma file.
// =============================================================================
// LiquidGlassLens.metal
// Universal Liquid Glass & Lens Refraction Metal Shader for SwiftUI
//
// Features:
// 1. iOS Continuous Squircle (p-norm ~4.2) / Capsule / Rounded Box SDF
// 2. Dual Displacement Modes:
//    - mode = 0.0: Fold-Free Magnification (UI 控件推荐，单调放大，防撕裂)
//    - mode = 1.0: Optical Inversion (物理光学倒像：凸透镜 UV 折叠、文字颠倒翻转)
// 3. 20° Tangential Shear (沿边缘切向流淌扭曲)
// 4. 6-Tap Continuous Spectrum Dispersion (蓝→青→品红顺滑流光色散，消除死板红绿边)
// 5. Blinn-Phong Specular Arc + Crisp Fresnel Hairline (灵动岛下边缘白色高光轮廓)
// =============================================================================

// Signed distance function for an iOS continuous curvature rounded box (squircle)
static float sdContinuousBox(float2 p, float2 b, float r, float n) {
    float2 q = abs(p) - b;
    if (n <= 2.02) {
        // Standard Euclidean rounded box
        return length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - r;
    } else {
        // Continuous curvature squircle via p-norm
        float2 m = max(q, float2(0.0));
        float s = pow(m.x, n) + pow(m.y, n);
        float outside = (s > 0.0) ? pow(s, 1.0 / n) : 0.0;
        return min(max(q.x, q.y), 0.0) + outside - r;
    }
}

[[ stitchable ]] half4 liquidGlassLens(
    float2 position,
    SwiftUI::Layer layer,
    float2 boundsSize,
    float cornerRadius,
    float cornerExponent,
    float bezel,
    float strength,
    float mode,
    float dispersion,
    float fresnel,
    float specular,
    float lightAngle
) {
    float2 center = boundsSize * 0.5;
    float2 p = position - center;

    // Resolve corner radius (capsule support: if < 0, use half of min dimension)
    float minHalf = min(boundsSize.x, boundsSize.y) * 0.5;
    float r = (cornerRadius < 0.0) ? minHalf : min(cornerRadius, minHalf);
    float2 halfExtents = max(boundsSize * 0.5 - float2(r), float2(0.0));

    // Evaluate SDF
    float d = sdContinuousBox(p, halfExtents, r, cornerExponent);

    // If completely outside the lens, return the un-distorted layer directly
    if (d > 1.5) {
        return layer.sample(position);
    }

    float inside = -d;
    float safeBezel = max(bezel, 1.0);
    float t = clamp(inside / safeBezel, 0.0, 1.0); // 0 at outer silhouette, 1 at center flat
    float edge = 1.0 - t;                          // 1 at outer silhouette, 0 at center flat

    // 1. Outward normal via central differences
    const float e = 1.0;
    float dx = sdContinuousBox(p + float2(e, 0.0), halfExtents, r, cornerExponent)
             - sdContinuousBox(p - float2(e, 0.0), halfExtents, r, cornerExponent);
    float dy = sdContinuousBox(p + float2(0.0, e), halfExtents, r, cornerExponent)
             - sdContinuousBox(p - float2(0.0, e), halfExtents, r, cornerExponent);
    float2 normalDir = normalize(float2(dx, dy) + float2(1e-6, 0.0));

    // 2. Dual Displacement Profile:
    // Mode 0: Fold-Free Magnification (Slope clamped under 0.88 to avoid inversion/shredding)
    float k = min(2.0 * strength / safeBezel, 0.88);
    float magFoldFree = 0.5 * k * safeBezel * edge * edge;

    // Mode 1: Optical Inversion (Steep slope that crosses fold limit -> creates real upside-down mirroring!)
    float magInversion = strength * (pow(edge, 1.6) + 1.35 * pow(edge, 3.2));

    // Blend between modes
    float m = mix(magFoldFree, magInversion, clamp(mode, 0.0, 1.0));

    // 3. 20° Tangential Shear (Ray sweeps around the rim contour)
    const float ct = 0.9397; // cos(20 deg)
    const float st = 0.3420; // sin(20 deg)
    float2 inward = -normalDir;
    float2 tangent = float2(-normalDir.y, normalDir.x);
    float2 baseOffset = (inward * ct + tangent * st) * m;

    // 4. 6-Tap Spectral Dispersion (Blue -> Cyan -> Magenta continuous spectrum)
    float spread = dispersion * 0.18 * edge;
    constexpr int TAPS = 6;
    const float3 weights[TAPS] = {
        float3(1.00, 0.05, 0.00), // Red
        float3(1.00, 0.58, 0.00), // Orange/Amber
        float3(0.50, 1.00, 0.15), // Yellow-Green
        float3(0.00, 1.00, 0.70), // Cyan
        float3(0.12, 0.35, 1.00), // Blue
        float3(0.65, 0.00, 0.85)  // Violet
    };
    const float sumR = 3.27, sumG = 2.93, sumB = 2.70;

    half4 col = half4(0.0);
    for (int i = 0; i < TAPS; ++i) {
        float u = float(i) / float(TAPS - 1);
        float f = 1.0 + spread * (2.0 * u - 1.0);
        float2 samplePos = position + baseOffset * f;
        half4 tap = layer.sample(samplePos);

        col.r += tap.r * half(weights[i].r);
        col.g += tap.g * half(weights[i].g);
        col.b += tap.b * half(weights[i].b);
        col.a += tap.a * half(1.0 / float(TAPS));
    }
    col.r /= half(sumR);
    col.g /= half(sumG);
    col.b /= half(sumB);

    // Edge lighting (modified — see header).
    float2 L = normalize(float2(cos(lightAngle), sin(lightAngle)));
    // 1 on the edge facing the light, 0 on the edge facing away.
    float lit = max(dot(normalDir, -L), 0.0);
    // Broad soft light: strongest at the silhouette on the lit side, present
    // all the way round, falling off quadratically over the edge band.
    float soft = (0.35 + 0.65 * lit) * edge * edge * specular;
    // Crisp 1.5pt hairline, brighter on the lit side.
    float hs = clamp(inside / 1.5, 0.0, 1.0);
    float hairline = (1.0 - hs * hs * (3.0 - 2.0 * hs)) * fresnel * (0.55 + 0.45 * lit);
    // Faint darkening on the far side, inside the outline.
    float counterRim = max(dot(normalDir, L), 0.0) * edge * edge * 0.10;

    // Light is added in proportion to coverage, so it never paints over
    // transparent backdrop.
    col.rgb += half3(half(soft + hairline)) * col.a;
    col.rgb = max(col.rgb - half3(half(counterRim) * col.a), half3(0.0));

    // Smooth edge alpha antialiasing
    float coverage = clamp(inside + 0.5, 0.0, 1.0);
    return mix(layer.sample(position), col, half(coverage));
}

// =============================================================================
// liquidGlassCanvas
// Multi-layer in-app backdrop refraction shader.
// Runs across the entire canvas / container, taking lensCenter and lensSize
// to physically refract and invert whatever backdrop content is behind the lens!
// =============================================================================
[[ stitchable ]] half4 liquidGlassCanvas(
    float2 position,
    SwiftUI::Layer layer,
    float2 lensCenter,
    float2 lensSize,
    float cornerRadius,
    float cornerExponent,
    float bezel,
    float strength,
    float mode,
    float dispersion,
    float fresnel,
    float specular,
    float lightAngle
) {
    float2 p = position - lensCenter;

    float minHalf = min(lensSize.x, lensSize.y) * 0.5;
    float r = (cornerRadius < 0.0) ? minHalf : min(cornerRadius, minHalf);
    float2 halfExtents = max(lensSize * 0.5 - float2(r), float2(0.0));

    float d = sdContinuousBox(p, halfExtents, r, cornerExponent);

    if (d > 1.5) {
        return layer.sample(position);
    }

    float inside = -d;
    float safeBezel = max(bezel, 1.0);
    float t = clamp(inside / safeBezel, 0.0, 1.0);
    float edge = 1.0 - t;

    // Normal via central difference
    const float e = 1.0;
    float dx = sdContinuousBox(p + float2(e, 0.0), halfExtents, r, cornerExponent)
             - sdContinuousBox(p - float2(e, 0.0), halfExtents, r, cornerExponent);
    float dy = sdContinuousBox(p + float2(0.0, e), halfExtents, r, cornerExponent)
             - sdContinuousBox(p - float2(0.0, e), halfExtents, r, cornerExponent);
    float2 normalDir = normalize(float2(dx, dy) + float2(1e-6, 0.0));

    // Dual Displacement
    float k = min(2.0 * strength / safeBezel, 0.88);
    float magFoldFree = 0.5 * k * safeBezel * edge * edge;
    float magInversion = strength * (pow(edge, 1.6) + 1.35 * pow(edge, 3.2));
    float m = mix(magFoldFree, magInversion, clamp(mode, 0.0, 1.0));

    // 20° Tangential shear
    const float ct = 0.9397;
    const float st = 0.3420;
    float2 inward = -normalDir;
    float2 tangent = float2(-normalDir.y, normalDir.x);
    float2 baseOffset = (inward * ct + tangent * st) * m;

    // 6-Tap Spectral Dispersion
    float spread = dispersion * 0.18 * edge;
    constexpr int TAPS = 6;
    const float3 weights[TAPS] = {
        float3(1.00, 0.05, 0.00),
        float3(1.00, 0.58, 0.00),
        float3(0.50, 1.00, 0.15),
        float3(0.00, 1.00, 0.70),
        float3(0.12, 0.35, 1.00),
        float3(0.65, 0.00, 0.85)
    };
    const float sumR = 3.27, sumG = 2.93, sumB = 2.70;

    half4 col = half4(0.0);
    for (int i = 0; i < TAPS; ++i) {
        float u = float(i) / float(TAPS - 1);
        float f = 1.0 + spread * (2.0 * u - 1.0);
        float2 samplePos = position + baseOffset * f;
        half4 tap = layer.sample(samplePos);

        col.r += tap.r * half(weights[i].r);
        col.g += tap.g * half(weights[i].g);
        col.b += tap.b * half(weights[i].b);
        col.a += tap.a * half(1.0 / float(TAPS));
    }
    col.r /= half(sumR);
    col.g /= half(sumG);
    col.b /= half(sumB);

    // Edge lighting (modified — see header).
    float2 L = normalize(float2(cos(lightAngle), sin(lightAngle)));
    // 1 on the edge facing the light, 0 on the edge facing away.
    float lit = max(dot(normalDir, -L), 0.0);
    // Broad soft light: strongest at the silhouette on the lit side, present
    // all the way round, falling off quadratically over the edge band.
    float soft = (0.35 + 0.65 * lit) * edge * edge * specular;
    // Crisp 1.5pt hairline, brighter on the lit side.
    float hs = clamp(inside / 1.5, 0.0, 1.0);
    float hairline = (1.0 - hs * hs * (3.0 - 2.0 * hs)) * fresnel * (0.55 + 0.45 * lit);
    // Faint darkening on the far side, inside the outline.
    float counterRim = max(dot(normalDir, L), 0.0) * edge * edge * 0.10;

    // Light is added in proportion to coverage, so it never paints over
    // transparent backdrop.
    col.rgb += half3(half(soft + hairline)) * col.a;
    col.rgb = max(col.rgb - half3(half(counterRim) * col.a), half3(0.0));

    float coverage = clamp(inside + 0.5, 0.0, 1.0);
    return mix(layer.sample(position), col, half(coverage));
}
