import SwiftUI

/// The curved mood bar: five stops, one glass chip, press-and-swipe.
///
/// You don't tap a mood. You press anywhere on the bar and slide — the chip
/// travels to your thumb, then follows it, and on release it magnetises onto
/// the nearest mood.
struct MoodArcBar: View {
    /// Continuous position, 0…4. Owned by the screen, driven from here.
    @Binding var progress: Double
    /// Fires once the chip has settled after release.
    var onSettle: (Int) -> Void = { _ in }

    var spec = ArcSpec()
    var chipSize = Figma.chipSize

    @State private var isDragging = false

    /// Nearest stop, recomputed continuously — drives the haptic and the label.
    private var nearest: Int { min(MoodScale.last, max(0, Int(progress.rounded()))) }

    var body: some View {
        GeometryReader { proxy in
            let geo = ArcGeometry(spec: spec, width: proxy.size.width, chipHeight: chipSize.height)

            ZStack(alignment: .topLeading) {
                // No `glassEffect` on either surface. See the Glass note in
                // FigmaTokens: it refracts what sits behind it, and behind
                // these is a near-white bar on a near-white background, so it
                // renders flat. Figma's Glass draws a rim and bevel regardless
                // of backdrop, so that is drawn here instead.
                ZStack {
                    ArcBarShape(geo: geo).fill(Figma.barFill)
                    ArcBarShape(geo: geo).fill(GlassBevel.bar.sheen)
                    ArcBarShape(geo: geo)
                        .stroke(GlassBevel.bar.rim, lineWidth: GlassBevel.bar.rimWidth)
                }
                .frame(width: geo.width, height: geo.height)

                ForEach(MoodScale.all) { mood in
                    stop(mood: mood, geo: geo)
                }

                chip(geo: geo)
            }
            .frame(width: geo.width, height: geo.height)
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
        .frame(height: ArcGeometry.boxHeight(spec: spec, chipHeight: chipSize.height))
        // One tick per crossing, a firmer one on settle. Fires on a real
        // device only — the Simulator has no haptic hardware.
        .sensoryFeedback(.selection, trigger: nearest)
        .sensoryFeedback(.impact(weight: .medium), trigger: isDragging) { old, new in
            old && !new
        }
    }

    // MARK: - Pieces

    /// The selected mood: a glass capsule sitting on the bar.
    ///
    /// 78.12 x 48.42 against the bar's 70, so it sits inside it rather than
    /// overhanging — which is what the Figma frame shows.
    private func chip(geo: ArcGeometry) -> some View {
        let u = progress / Double(MoodScale.last)
        let centre = geo.point(at: CGFloat(u))

        // Bottom to top: body fill, the bevel's sheen, the lit rim, then the
        // icon. `compositingGroup` flattens the stack before the shadow, so
        // the shadow is cast by the composed capsule rather than by each layer.
        return ZStack {
            Capsule().fill(Figma.chipFill)
            Capsule().fill(GlassBevel.chip.sheen)
            Capsule().strokeBorder(GlassBevel.chip.rim, lineWidth: GlassBevel.chip.rimWidth)
            MoodFace(progress: progress, size: Figma.iconSize, color: Figma.iconInk)
        }
        .frame(width: chipSize.width, height: chipSize.height)
        .compositingGroup()
        .shadow(
            color: Figma.chipShadowColor,
            radius: Figma.chipShadowRadius,
            x: 0,
            y: Figma.chipShadowY
        )
            .scaleEffect(isDragging ? ArcGeometry.pressScale : 1)
            .position(centre)
    }

    /// One unselected stop. It fades as the chip arrives, so the chip reads as
    /// picking the stop up rather than parking on top of it.
    private func stop(mood: Mood, geo: ArcGeometry) -> some View {
        let u = CGFloat(mood.id) / CGFloat(MoodScale.last)
        let distance = abs(progress - Double(mood.id))
        let visible = min(1, max(0, (distance - 0.55) / 0.65))

        return MoodFace(progress: Double(mood.id), size: Figma.iconSize, color: Figma.iconInk)
            .opacity(visible)
            .scaleEffect(0.8 + 0.2 * visible)
            .position(geo.point(at: u))
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
                progress = Double(geo.u(atX: value.location.x)) * Double(MoodScale.last)
            }
            .onEnded { _ in
                isDragging = false
                let settled = nearest
                progress = Double(settled)
                onSettle(settled)
            }
    }
}
