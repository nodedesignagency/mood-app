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

    /// The bar: the layer's flat fill and nothing else.
    ///
    /// The file puts a Glass effect on it too, but on a 58pt band that is only
    /// ~10 levels off the page behind it there is no room for a highlight: any
    /// edge bright enough to read merges with the background and eats the
    /// silhouette, and any edge dim enough to keep the silhouette is invisible
    /// up close. Flat is what the file *looks* like at this size.
    private func bar(geo: ArcGeometry) -> some View {
        ArcBarShape(geo: geo).fill(Figma.barFill)
    }

    /// The selected mood: a glass capsule riding on the bar.
    ///
    /// `Capsule` is insettable, so the rim can say `strokeBorder` outright.
    /// `compositingGroup` flattens the stack before the shadow, so the shadow
    /// is cast by the composed capsule rather than by each layer in turn.
    private func chip(geo: ArcGeometry) -> some View {
        let glass = FigmaGlass.chip

        return ZStack {
            Capsule().fill(Figma.chipFill)
            Capsule().fill(glass.sheen)
            Capsule().strokeBorder(glass.rim, lineWidth: glass.rimWidth)
            MoodFace(progress: progress, size: Figma.chipIconSize, color: Figma.iconInk)
        }
        .frame(width: Figma.chipSize.width, height: Figma.chipSize.height)
        .compositingGroup()
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
