import SwiftUI

/// The curved mood bar: five stops, one glass chip, press-and-swipe.
///
/// You don't tap a mood. You press anywhere on the bar and slide — the chip
/// travels to your thumb, then follows it, and on release it magnetises onto
/// the nearest mood.
///
/// The chip is a refracting lens (see `LensCanvas`) and nothing more: it
/// carries no icon of its own. The five faces stay where they are in the bar,
/// always visible, and the one you see "in" the chip is the stop beneath it,
/// seen through the glass — the same as the system's segmented control, where
/// the labels stay put and the glass slides over them. Under a thumb only
/// the frame swells; the face under it does not move or grow.
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

    var body: some View {
        GeometryReader { proxy in
            let geo = ArcGeometry(width: proxy.size.width)
            let chipCenter = geo.point(at: progress)
            // The chip lies along the curve, not level: the bar climbs ~9°
            // at its left end and falls ~9° at its right, and a level capsule
            // there pokes out of the bar's lower edge.
            let chipAngle = geo.angle(at: progress)

            // Everything in here is what the lens refracts. Order matters:
            // the chip's translucent body goes *under* the faces, so the face
            // beneath the chip stays fully dark instead of being washed by
            // 65% white, and the lens on top bends whatever crosses its edge.
            ZStack(alignment: .topLeading) {
                bar(geo: geo)

                chipBody(at: chipCenter, angle: chipAngle)

                ForEach(MoodScale.all) { mood in
                    stop(mood: mood, geo: geo)
                }
            }
            .lensCanvas(center: chipCenter, size: chipSize, rotation: chipAngle, config: Figma.chipGlass)
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
    /// the refracted layer, under the faces and exactly under the lens, so
    /// the glass edge the shader draws lands on its silhouette.
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

    /// One stop. Always visible: the chip never hides or replaces a face, it
    /// slides over it, and the face turns blue as it arrives.
    private func stop(mood: Mood, geo: ArcGeometry) -> some View {
        MoodIcon(mood: mood, size: Figma.stopIconSize, selected: selection(of: mood))
            .position(geo.point(at: Double(mood.id)))
    }

    /// How much of a stop's blue shows, 0…1.
    ///
    /// Full blue when the chip is centred on it, gone by 0.85 of a step away —
    /// roughly where the chip's edge leaves it, so the colour tracks what the
    /// glass is actually covering. Smoothstepped rather than linear so the
    /// handover eases at both ends instead of starting and stopping abruptly.
    /// Two neighbours are never both fully blue.
    private func selection(of mood: Mood) -> Double {
        let t = min(1, abs(progress - Double(mood.id)) / 0.85)
        return 1 - t * t * (3 - 2 * t)
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
