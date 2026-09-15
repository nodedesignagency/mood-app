import SwiftUI

/// The daily check-in.
///
/// Laid out in the Figma artboard's own coordinates — the "Active state"
/// frame, 393 × 852 — and scaled once to fit the device, so every number
/// below can be read straight off the file and checked against it.
///
/// This was tried once as a stack of springs and paddings and abandoned:
/// the file overlaps things a stack cannot. The mascot's box runs from 184
/// to 576 while the mood word sits at 528, inside it, over the transparent
/// lower corner of the artwork. A stack has to put one after the other, and
/// the sum does not fit on any iPhone — which is why the mascot had been
/// shrunk from 392 to 260.
///
/// Children are placed with `position`, which works in the parent's own
/// coordinates and takes the space it is offered. An earlier attempt used
/// `offset` inside a `topLeading` stack instead; the stack then sized itself
/// to its tallest child rather than the artboard, and the frame around it
/// centred that — dropping everything 230 points down the screen and pushing
/// the bar off the bottom. `position` has no such trap.
struct MoodCheckInView: View {
    /// Continuous position along the bar, 0…4. The single source of truth.
    @State private var progress: Double = 2
    /// The mood word's entrance: it starts a little small and displaced in
    /// the direction the scale is moving, then springs home.
    @State private var wordScale: CGFloat = 1
    @State private var wordLift: CGFloat = 0
    /// True while a thumb is on the bar. Held here rather than in the bar so
    /// the glow and the mood word can move on the same curve as the chip.
    @State private var isDragging = false

    var greetingName = "Jimmy"

    private var mood: Mood { MoodScale.nearest(to: progress) }

    var body: some View {
        GeometryReader { proxy in
            // One uniform factor, so nothing distorts. The artboard's aspect
            // (393:852) is within half a percent of every iPhone this targets,
            // so the slack is a point or two, not a letterbox.
            let scale = min(proxy.size.width / Figma.artboard.width,
                            proxy.size.height / Figma.artboard.height)

            ZStack {
                // Behind the artboard as well as inside it, so the point or
                // two of slack at the edges is the page colour and not black.
                Figma.background

                artboard
                    .frame(width: Figma.artboard.width, height: Figma.artboard.height)
                    .scaleEffect(scale)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Layout

    /// Frames measured off the file. Text sits in full-width slots rather than
    /// its own measured box, so a longer name or mood word cannot clip; the
    /// centres are the same either way, since all of it is centred on the
    /// artboard. The question keeps its 273 because that is what wraps it.
    private var artboard: some View {
        ZStack {
            // Inside the artboard too, so the glow's soft light has something
            // to blend against rather than transparency.
            Figma.background
            glow

            place(x: 0, y: 80, w: 393, h: 16) { greeting }
            place(x: 60, y: 104, w: 273, h: 84) { question }
            place(x: 0, y: 184, w: 393, h: 392) { mascot }
            place(x: 0, y: 528, w: 393, h: 57) { moodLabel }
            place(x: 132, y: 588, w: 128.45, h: 49.45) { continueButton }
            place(x: 0, y: 699, w: 393, h: 30) { hint }
            place(x: 0, y: 744, w: 393, h: BarLayout.frameHeight) {
                // The bar carries its own 5pt side inset, measured from its
                // frame, so it takes the full artboard width.
                MoodArcBar(progress: $progress, isDragging: $isDragging)
            }
        }
    }

    /// Place a view at a frame measured off the artboard.
    private func place<V: View>(
        x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
        @ViewBuilder _ content: () -> V
    ) -> some View {
        content()
            .frame(width: w, height: h)
            .position(x: x + w / 2, y: y + h / 2)
    }

    // MARK: - Pieces

    /// Frame 2147226789 — see the Glow section of `Figma` for what is in it
    /// and what was left out.
    ///
    /// The file gives one fixed #C5E0FF, which is Okay's. Every mood has its
    /// own, blended continuously, so the whole page carries the mood and not
    /// just the word.
    private var glow: some View {
        ZStack {
            Circle()
                .fill(MoodScale.glow(at: progress))
                .frame(width: Figma.glowDiameter, height: Figma.glowDiameter)
                .blur(radius: Figma.glowBlur)
                .position(Figma.glowCentre)

            if let rays = Art.rays {
                Image(uiImage: rays)
                    .resizable()
                    .frame(width: Figma.raysSize.width, height: Figma.raysSize.height)
                    .blendMode(.softLight)
                    .position(Figma.raysCentre)
            }
        }
        .animation(MoodMotion.follow(isDragging), value: progress)
    }

    private var greeting: some View {
        Text("Hey, \(greetingName) 👋")
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(Figma.textMuted)
    }

    private var question: some View {
        Text("How Are You\nFeeling Today?")
            .font(.system(size: 32, weight: .medium, design: .rounded))
            .tracking(-1.38)
            .lineSpacing(Figma.questionLineSpacing)
            .multilineTextAlignment(.center)
            .foregroundStyle(Figma.textPrimary)
    }

    private var moodLabel: some View {
        Text(mood.label)
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .tracking(-1.38)
            .foregroundStyle(MoodScale.accent(at: progress))
            // A crossfade, not `numericText`. That one interpolates glyph by
            // glyph, because it is built for rolling digits — so between
            // words of different lengths it blends letter positions, and a
            // spring being retargeted a hundred times a second freezes it
            // part-way. That is where "Loay" and "G kay" came from, and why
            // it only looked right on a tap, which gives it one clean run.
            // A crossfade has no glyphs to confuse: interrupt it and it just
            // dissolves from wherever it had got to.
            .contentTransition(.opacity)
            .animation(MoodMotion.follow(isDragging), value: progress)
            // The crossfade alone is inert, so the word also arrives: a
            // little small, and from below when the mood is rising or above
            // when it is falling, springing home.
            //
            // Scale and offset are single continuous numbers, which is the
            // whole point — a spring can retarget either of them from
            // wherever it is, so being interrupted mid-drag costs nothing.
            // That is what `numericText` could not do, and it is why this
            // gets the movement back without getting the mangling back.
            .scaleEffect(wordScale)
            .offset(y: wordLift)
            .onChange(of: mood.id, initial: false) { was, now in
                wordLift = now > was ? 12 : -12
                wordScale = 0.88
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                    wordLift = 0
                    wordScale = 1
                }
            }
    }

    /// The mascot.
    ///
    /// Keyed on the image itself rather than on the mood: while every mood
    /// shares one drawing, the key does not change and nothing cross-fades a
    /// picture with itself. It starts cross-fading on its own the moment the
    /// moods have different artwork.
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
    }

    /// Continue: the file's 70% white capsule, with its glass edge drawn by
    /// the shader and its drop shadow. Not the system button style — that
    /// draws its own material over the page, and on a near-white page it
    /// comes out flat.
    private var continueButton: some View {
        Button {
            // Wire to the next step in the flow.
        } label: {
            HStack(spacing: Figma.buttonGap) {
                Text("Continue")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .tracking(-0.18)
            .foregroundStyle(Figma.textPrimary)
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

    /// The hint. Its icon is 30 wide and the words start at 31, so they sit
    /// a point apart.
    private var hint: some View {
        HStack(spacing: 1) {
            if let icon = Art.hintSwipe {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 30, height: 30)
            }
            Text("Swipe to select mood")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(Figma.textMuted)
        }
    }
}

#Preview {
    MoodCheckInView()
}
