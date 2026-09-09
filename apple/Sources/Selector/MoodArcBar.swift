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
    @Namespace private var glassNamespace

    /// Nearest stop, recomputed continuously — drives the haptic and the label.
    private var nearest: Int { min(MoodScale.last, max(0, Int(progress.rounded()))) }

    var body: some View {
        GeometryReader { proxy in
            let geo = ArcGeometry(spec: spec, width: proxy.size.width, chipHeight: chipSize.height)

            ZStack(alignment: .topLeading) {
                // A shared container lets the chip and the bar sample the same
                // backdrop and blend into each other as they overlap, instead
                // of reading as two unrelated pieces of glass.
                GlassEffectContainer(spacing: 18) {
                    ZStack(alignment: .topLeading) {
                        ArcBarShape(geo: geo)
                            .fill(Figma.barFill)
                            .glassEffect(.regular, in: ArcBarShape(geo: geo))
                            .frame(width: geo.width, height: geo.height)

                        chip(geo: geo)
                    }
                }

                ForEach(MoodScale.all) { mood in
                    stop(mood: mood, geo: geo)
                }
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
        .frame(height: ArcGeometry(spec: spec, width: 400, chipHeight: chipSize.height).height)
        // One tick per crossing, a firmer one on settle. Fires on a real
        // device only — the Simulator has no haptic hardware.
        .sensoryFeedback(.selection, trigger: nearest)
        .sensoryFeedback(.impact(weight: .medium), trigger: isDragging) { old, new in
            old && !new
        }
    }

    // MARK: - Pieces

    /// The selected mood: a glass lozenge riding proud of the bar.
    private func chip(geo: ArcGeometry) -> some View {
        let u = progress / Double(MoodScale.last)
        let centre = geo.point(at: CGFloat(u))

        return Capsule(style: .continuous)
            .fill(Figma.chipFill)
            .glassEffect(
                // `.interactive()` is what makes it flex and brighten under a
                // finger — the "when pressed" frame comes free with it.
                .regular.interactive(),
                in: Capsule(style: .continuous)
            )
            .glassEffectID("chip", in: glassNamespace)
            .overlay {
                MoodFace(progress: progress, size: Figma.iconSize, color: Figma.iconInk)
            }
            .frame(width: chipSize.width, height: chipSize.height)
            .shadow(
                color: Figma.chipShadowColor,
                radius: Figma.chipShadowRadius,
                x: 0,
                y: Figma.chipShadowY
            )
            .scaleEffect(isDragging ? 1.06 : 1)
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
