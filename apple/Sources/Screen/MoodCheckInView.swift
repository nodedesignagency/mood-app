import SwiftUI

/// Horizontal gutter for the screen's text content.
private let SPACING_GUTTER: CGFloat = 20

/// The daily check-in.
///
/// Layout follows the Figma mockup: greeting, question, mascot, mood word,
/// Continue, hint, bar. Sizes and colours marked PLACEHOLDER are read off the
/// mockup image rather than the Figma file — see apple/README.md.
struct MoodCheckInView: View {
    /// Continuous position along the bar, 0…4. The single source of truth.
    @State private var progress: Double = 2

    var greetingName = "Jimmy"

    private var mood: Mood { MoodScale.nearest(to: progress) }

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                Text("Hey, \(greetingName) 👋")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Text("How Are You\nFeeling Today?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.top, 10)

                Spacer(minLength: 12)

                mascot

                Spacer(minLength: 12)

                Text(mood.label)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(MoodScale.accent(at: progress))
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: mood.id)

                continueButton
                    .padding(.top, 14)

                hint
                    .padding(.top, 26)

                MoodArcBar(progress: $progress)
                    .padding(.top, 10)
                    // The bar carries its own 5pt side inset, measured from
                    // the frame, so it has to escape the stack's gutter.
                    .padding(.horizontal, -SPACING_GUTTER)
            }
            .padding(.horizontal, SPACING_GUTTER)
        }
    }

    // MARK: - Pieces

    /// The app's background colour, with a mood-tinted bloom over it.
    ///
    /// The flat colour matters more than it looks: the bar's fill is E9EDF4 at
    /// 60%, so it lands about ten levels off whatever sits behind it. On pure
    /// white that reads as no colour at all; on F8F9FC it reads.
    private var backdrop: some View {
        GeometryReader { proxy in
            // Everything about the glow is fixed in the file, so the only
            // thing to work out is scale: artboard units multiplied by how
            // much wider this screen is than the 393 it was drawn for.
            let scale = proxy.size.width / Figma.artboard.width
            let size = proxy.size

            ZStack {
                Figma.background

                Circle()
                    .fill(Figma.glowFill)
                    .frame(
                        width: Figma.glowDiameter * scale,
                        height: Figma.glowDiameter * scale
                    )
                    .blur(radius: Figma.glowBlur * scale)
                    .position(
                        x: size.width * Figma.glowCentre.x,
                        y: size.height * Figma.glowCentre.y
                    )

                if let rays = Art.rays {
                    Image(uiImage: rays)
                        .resizable()
                        .frame(
                            width: Figma.raysSize.width * scale,
                            height: Figma.raysSize.height * scale
                        )
                        .blendMode(.softLight)
                        .position(
                            x: size.width * Figma.raysCentre.x,
                            y: size.height * Figma.raysCentre.y
                        )
                }
            }
        }
        .ignoresSafeArea()
    }

    /// The mascot.
    ///
    /// Keyed on the image itself rather than on the mood: while every mood
    /// shares one drawing, the key does not change and nothing cross-fades
    /// a picture with itself. It starts cross-fading on its own the moment
    /// the moods have different artwork.
    private var mascot: some View {
        Group {
            if let art = Art.mascot(mood) {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFit()
                    .id(ObjectIdentifier(art))
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.22), value: mood.id)
            } else {
                MoodFace(progress: progress, size: 190, color: MoodScale.accent(at: progress))
            }
        }
        .frame(maxWidth: 260, maxHeight: 260)
    }

    private var continueButton: some View {
        Button {
            // Wire to the next step in the flow.
        } label: {
            HStack(spacing: Figma.buttonGap) {
                Text("Continue")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(Figma.iconInk)
            .frame(width: Figma.buttonSize.width, height: Figma.buttonSize.height)
            .background {
                Capsule()
                    .fill(Figma.buttonFill)
                    .liquidGlassLens(Figma.buttonGlass)
                    .shadow(color: Figma.shadowColor, radius: Figma.shadowRadius, x: 0, y: Figma.shadowY)
            }
        }
        .buttonStyle(.plain)
    }

    private var hint: some View {
        HStack(spacing: 7) {
            Image(systemName: "hand.point.up.left")
            Text("Swipe to select mood")
        }
        .font(.system(size: 15, weight: .regular, design: .rounded))
        .foregroundStyle(.secondary)
    }
}

#Preview {
    MoodCheckInView()
}
