import SwiftUI

/// The curved mood bar: five stops, one glass chip, press-and-swipe.
///
/// You don't tap a mood. You press anywhere on the bar and slide — the chip
/// travels to your thumb, then follows it, and on release it magnetises onto
/// the nearest mood.
///
/// The chip is a refracting lens (see `LensCanvas`). Under a thumb it swells
/// to the file's pressed size, the stop icons bend and fringe through its
/// edge as it passes over them, and it settles with a spring.
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

    /// Nearest stop, recomputed continuously — drives the haptic and the label.
    private var nearest: Int {
        min(BarLayout.last, max(0, Int(progress.rounded())))
    }

    private var chipSize: CGSize { isDragging ? Figma.chipPressedSize : Figma.chipSize }
    private var chipIconSize: CGFloat { isDragging ? Figma.chipPressedIconSize : Figma.chipIconSize }

    var body: some View {
        GeometryReader { proxy in
            let geo = ArcGeometry(width: proxy.size.width)
            let chipCenter = geo.point(at: progress)
            // The chip lies along the curve, not level: the bar climbs ~12°
            // at its left end and falls ~8° at its right, and a level capsule
            // there pokes out of the bar's lower edge.
            let chipAngle = geo.angle(at: progress)

            ZStack(alignment: .topLeading) {
                // Everything in here is what the lens refracts: the bar, the
                // stops, and the chip's own translucent body — so the stops
                // bend through the chip's edge as it slides over them.
                ZStack(alignment: .topLeading) {
                    bar(geo: geo)

                    ForEach(MoodScale.all) { mood in
                        stop(mood: mood, geo: geo)
                    }

                    chipBody(at: chipCenter, angle: chipAngle)
                }
                .lensCanvas(center: chipCenter, size: chipSize, rotation: chipAngle, config: Figma.chipGlass)

                // Above the lens, so it stays crisp while everything under
                // it bends.
                MoodFace(progress: progress, size: chipIconSize, color: Figma.iconInk)
                    .rotationEffect(chipAngle)
                    .position(chipCenter)
                    .allowsHitTesting(false)
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
            // The swell on press and the settle on release.
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isDragging)
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

    /// The bar: the layer's flat fill. See `Figma.barFill` for why nothing
    /// more is drawn on it.
    private func bar(geo: ArcGeometry) -> some View {
        ArcBarShape(geo: geo).fill(Figma.barFill)
    }

    /// The chip's body: the file's 65% white and its drop shadow. It sits in
    /// the refracted layer, exactly under the lens, so the glass edge the
    /// shader draws lands on its silhouette.
    private func chipBody(at center: CGPoint, angle: Angle) -> some View {
        Capsule()
            .fill(Figma.chipFill)
            .frame(width: chipSize.width, height: chipSize.height)
            // Rotated before the shadow, so the shadow still falls straight
            // down the screen rather than tilting with the chip.
            .rotationEffect(angle)
            .shadow(color: Figma.shadowColor, radius: Figma.shadowRadius, x: 0, y: Figma.shadowY)
            .position(center)
    }

    /// One unselected stop.
    ///
    /// Hidden only while the chip is nearly on top of it — otherwise its icon
    /// and the chip's would double up. The window is narrow on purpose: a
    /// stop should be visible, and bending through the lens, for as much of
    /// the chip's approach as possible.
    private func stop(mood: Mood, geo: ArcGeometry) -> some View {
        let distance = abs(progress - Double(mood.id))
        let visible = min(1, max(0, (distance - 0.25) / 0.35))

        return MoodFace(progress: Double(mood.id), size: Figma.stopIconSize, color: Figma.iconInk)
            .opacity(visible)
            .position(geo.point(at: Double(mood.id)))
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
