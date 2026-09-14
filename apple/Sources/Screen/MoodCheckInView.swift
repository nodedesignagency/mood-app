import SwiftUI

/// The Figma artboard this screen is laid out in: the "Active state" frame
/// (node 1:316), 393 × 852.
private enum Canvas {
    static let width: CGFloat = 393
    static let height: CGFloat = 852
}

/// The daily check-in.
///
/// Laid out in the artboard's own coordinates and scaled once to fit the
/// device, so every number below can be read straight off the Figma file and
/// checked against it. The screen used to be a `VStack` of springs and
/// paddings, which meant nothing landed where it was drawn — the bar ended up
/// flush against the bottom of the screen instead of the 20pt clear of it that
/// the file asks for, and the mascot box was 260pt against a designed 392.
struct MoodCheckInView: View {
    /// Continuous position along the bar, 0…4. The single source of truth.
    @State private var progress: Double = 2

    var greetingName = "Jimmy"

    private var mood: Mood { MoodScale.nearest(to: progress) }

    var body: some View {
        GeometryReader { proxy in
            // One uniform factor, so nothing stretches. The artboard's aspect
            // (393:852) is within half a percent of every iPhone this targets,
            // so the leftover slack is a point or two, not a letterbox.
            let scale = min(proxy.size.width / Canvas.width,
                            proxy.size.height / Canvas.height)

            ZStack {
                backdrop
                artboard
                    .frame(width: Canvas.width, height: Canvas.height)
                    .scaleEffect(scale)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Layout

    /// Frames measured off the file. Everything on this screen is centred on
    /// the artboard, so the x values below are all `(393 - width) / 2` and are
    /// written as a centred full-width slot instead, which survives a longer
    /// name or a longer mood word without clipping.
    private var artboard: some View {
        ZStack(alignment: .topLeading) {
            place(y: 80, height: 16) { greeting }
            place(y: 104, width: 273, height: 84) { question }
            place(y: 184, width: 392, height: 392) { mascot }
            place(y: 528, height: 57) { moodLabel }
            place(y: 588, width: 128.45, height: 49.45) { continueButton }
            place(y: 699, width: 204, height: 30) { hint }
            place(y: 744, height: BarLayout.frameHeight) {
                // The bar carries its own 5pt side inset internally, measured
                // from its frame, so it takes the full artboard width.
                MoodArcBar(progress: $progress)
            }
        }
    }

    /// Place a view in a centred slot at a measured y on the artboard.
    private func place<V: View>(
        y: CGFloat,
        width: CGFloat = Canvas.width,
        height: CGFloat,
        @ViewBuilder _ content: () -> V
    ) -> some View {
        content()
            .frame(width: width, height: height)
            .offset(x: (Canvas.width - width) / 2, y: y)
    }

    // MARK: - Pieces

    /// The app's background colour, with a mood-tinted bloom over it.
    ///
    /// The flat colour matters more than it looks: the bar's fill is E9EDF4 at
    /// 60%, so it lands about ten levels off whatever sits behind it. On pure
    /// white that reads as no colour at all; on F8F9FC it reads.
    ///
    /// The bloom is placed on the file's own glow layer ("Frame 2147226789",
    /// 565 × 592 at (−86, 108)), whose centre works out at (0.50, 0.47) of the
    /// artboard.
    private var backdrop: some View {
        ZStack {
            Figma.background
            RadialGradient(
                colors: [MoodScale.glow(at: progress).opacity(0.9), .clear],
                center: .init(x: 0.50, y: 0.47),
                startRadius: 0,
                endRadius: 300
            )
            .animation(.easeOut(duration: 0.25), value: progress)
        }
        .ignoresSafeArea()
    }

    // Type sizes are read back from each text layer's measured box, since the
    // file's type styles were not among the values that came across. The
    // greeting's box is 89 × 16, the question's 273 × 84 over two lines (so a
    // 42pt line), "Okay" 102 × 57, "Continue" 73 × 23, the hint 173 × 21.

    private var greeting: some View {
        Text("Hey, \(greetingName) 👋")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private var question: some View {
        Text("How Are You\nFeeling Today?")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
    }

    private var moodLabel: some View {
        Text(mood.label)
            .font(.system(size: 46, weight: .bold, design: .rounded))
            .foregroundStyle(MoodScale.accent(at: progress))
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.25), value: mood.id)
    }

    /// PLACEHOLDER for the rendered character.
    ///
    /// The slot is the full 392 × 392 the file gives it, so dropping in
    /// `mascot-<key>` images fills it correctly. The drawn stand-in is smaller
    /// on purpose — it is a face, not the artwork, and at 392 it would read as
    /// a bug rather than a placeholder. When the mascot videos land, swap this
    /// for a scrubbed `AVPlayer` driven off `progress`; the slot does not move.
    private var mascot: some View {
        Group {
            if UIImage(named: mood.mascot) != nil {
                Image(mood.mascot)
                    .resizable()
                    .scaledToFit()
                    .id(mood.id)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.22), value: mood.id)
            } else {
                MoodFace(progress: progress, size: 220, color: MoodScale.accent(at: progress))
            }
        }
    }

    private var continueButton: some View {
        Button {
            // Wire to the next step in the flow.
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .tint(.primary)
    }

    private var hint: some View {
        HStack(spacing: 7) {
            Image(systemName: "hand.point.up.left")
            Text("Swipe to select mood")
        }
        .font(.system(size: 16, weight: .regular, design: .rounded))
        .foregroundStyle(.secondary)
    }
}

#Preview {
    MoodCheckInView()
}
