import SwiftUI

/// The curved mood bar: five stops, one glass chip, press-and-swipe.
///
/// You don't tap a mood. You press anywhere on the bar and slide — the chip
/// travels to your thumb, then follows it, and on release it magnetises onto
/// the nearest mood.
///
/// The chip is real Liquid Glass. Under a thumb it swells to the file's
/// pressed size, the stop icons refract through it as it passes over them,
/// and it settles with a spring — the same behaviour as the system's own
/// segmented control, which is what the design is modelled on.
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

    var body: some View {
        GeometryReader { proxy in
            let geo = ArcGeometry(width: proxy.size.width)

            ZStack(alignment: .topLeading) {
                bar(geo: geo)

                // Drawn before the chip so they sit beneath its glass, which
                // is what makes them bend as it slides over them.
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

    /// The bar: the layer's flat fill. See `Figma.barFill` for why nothing
    /// more is drawn on it.
    private func bar(geo: ArcGeometry) -> some View {
        ArcBarShape(geo: geo).fill(Figma.barFill)
    }

    /// The selected mood: a capsule of Liquid Glass riding on the bar.
    ///
    /// The glass follows the view's frame, so animating the frame between
    /// the resting and pressed sizes is the swell — no scale transform, which
    /// would also scale the rim and the shadow. `.interactive()` lets the
    /// glass itself respond to the touch as well.
    ///
    /// No shadow is added: the effect casts its own. The stop beneath is
    /// faded out (see `stop`) so the chip's icon is the only one showing at
    /// rest; while sliding, the neighbours come through the glass.
    private func chip(geo: ArcGeometry) -> some View {
        let size = isDragging ? Figma.chipPressedSize : Figma.chipSize
        let icon = isDragging ? Figma.chipPressedIconSize : Figma.chipIconSize

        return MoodFace(progress: progress, size: icon, color: Figma.iconInk)
            .frame(width: size.width, height: size.height)
            .glassEffect(.regular.interactive(), in: .capsule)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isDragging)
            .position(geo.point(at: progress))
    }

    /// One unselected stop.
    ///
    /// Hidden only while the chip is nearly on top of it — otherwise its icon
    /// and the chip's would double up. The window is narrow on purpose: a
    /// stop should be visible, and refracting through the glass, for as much
    /// of the chip's approach as possible.
    private func stop(mood: Mood, geo: ArcGeometry) -> some View {
        let distance = abs(progress - Double(mood.id))
        let visible = min(1, max(0, (distance - 0.25) / 0.35))

        return MoodFace(progress: Double(mood.id), size: Figma.stopIconSize, color: Figma.iconInk)
            .opacity(visible)
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
