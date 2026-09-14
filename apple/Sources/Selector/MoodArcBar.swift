import SwiftUI

/// The curved mood bar: five stops, one glass chip, press-and-swipe.
///
/// You don't tap a mood. You press anywhere on the bar and slide — the chip
/// travels to your thumb, then follows it, and on release it magnetises onto
/// the nearest mood.
///
/// Positions come from `BarLayout`, measured out of the Figma file, and the
/// bar's outline from `ArcBarShape`, transcribed from it. Nothing here
/// computes where anything goes.
struct MoodArcBar: View {
    /// Continuous position, 0…4. Owned by the screen, driven from here.
    @Binding var progress: Double
    /// Fires once the chip has settled after release.
    var onSettle: (Int) -> Void = { _ in }

    @State private var isDragging = false

    /// How much the chip grows while a thumb is on it.
    private let pressScale: CGFloat = 1.06

    /// Nearest stop, recomputed continuously — drives the haptic and the label.
    private var nearest: Int {
        min(BarLayout.last, max(0, Int(progress.rounded())))
    }

    var body: some View {
        GeometryReader { proxy in
            let geo = ArcGeometry(width: proxy.size.width)

            ZStack(alignment: .topLeading) {
                bar(geo: geo)

                ForEach(MoodScale.all) { mood in
                    stop(mood: mood, geo: geo)
                }

                chip(geo: geo)
            }
            .frame(width: proxy.size.width, height: geo.height)
            .contentShape(Rectangle())
            .gesture(drag(geo: geo))
            // Tracking springs tight so the chip feels welded to the thumb;
            // the release spring is looser and overshoots slightly, which is
            // what gives the snap its weight.
            .animation(
                isDragging
                    ? .interactiveSpring(response: 0.20, dampingFraction: 0.86)
                    : .spring(response: 0.42, dampingFraction: 0.62),
                value: progress
            )
        }
        .frame(height: BarLayout.frameHeight)
        // One tick per crossing, a firmer one on settle. Fires on a real
        // device only — the Simulator has no haptic hardware.
        .sensoryFeedback(.selection, trigger: nearest)
        .sensoryFeedback(.impact(weight: .medium), trigger: isDragging) { old, new in
            old && !new
        }
    }

    // MARK: - Pieces

    /// The bar: system Liquid Glass in the shape Figma drew, tinted with the
    /// layer's own fill. That is the whole layer — see the Glass note in
    /// `FigmaTokens` for why there is no rim, bevel or shadow drawn here.
    ///
    /// `glassEffect` puts the glass *behind* its content in the given shape,
    /// so the content is an empty full-size layer and the shape does the work.
    private func bar(geo: ArcGeometry) -> some View {
        Color.clear
            .glassEffect(.regular.tint(Figma.barFill), in: ArcBarShape(geo: geo))
    }

    /// The selected mood: a glass capsule riding on the bar.
    ///
    /// Deliberately *not* in a `GlassEffectContainer` with the bar. A container
    /// blends the shapes inside it as they approach, and this chip does not
    /// approach the bar — it sits on top of it, permanently, which unions the
    /// two into one blob. Kept separate, the chip's glass refracts the bar
    /// beneath it instead, which is both the look in the file and the one
    /// place on this screen where there is genuinely something to refract.
    private func chip(geo: ArcGeometry) -> some View {
        MoodFace(progress: progress, size: Figma.chipIconSize, color: Figma.iconInk)
            .frame(width: Figma.chipSize.width, height: Figma.chipSize.height)
            .glassEffect(.regular.tint(Figma.chipFill), in: .capsule)
            // The one shadow the design actually specifies.
            .shadow(
                color: Figma.chipShadowColor,
                radius: Figma.chipShadowRadius,
                x: 0,
                y: Figma.chipShadowY
            )
            .scaleEffect(isDragging ? pressScale : 1)
            .position(geo.point(at: progress))
    }

    /// One unselected stop. It fades as the chip arrives, so the chip reads as
    /// picking the stop up rather than parking on top of it.
    private func stop(mood: Mood, geo: ArcGeometry) -> some View {
        let distance = abs(progress - Double(mood.id))
        let visible = min(1, max(0, (distance - 0.55) / 0.65))

        return MoodFace(progress: Double(mood.id), size: Figma.stopIconSize, color: Figma.iconInk)
            .opacity(visible)
            .scaleEffect(0.85 + 0.15 * visible)
            .position(geo.point(at: Double(mood.id)))
            .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private func drag(geo: ArcGeometry) -> some Gesture {
        // `minimumDistance: 0` fires on touch-down rather than after a
        // threshold: the whole point is press-and-move, so there is nothing to
        // disambiguate against.
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                progress = geo.index(atX: value.location.x)
            }
            .onEnded { _ in
                isDragging = false
                let settled = nearest
                progress = Double(settled)
                onSettle(settled)
            }
    }
}
