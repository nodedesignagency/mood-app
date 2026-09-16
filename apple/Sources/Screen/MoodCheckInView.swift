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
    /// True while a thumb is on the bar. Held here rather than in the bar so
    /// the glow and the mood word can move on the same curve as the chip.
    @State private var isDragging = false
    /// The screen arriving, 0 → 1, once per launch. Every element takes a
    /// slice of it — see `Entrance`.
    @State private var entrance: Double = 0
    /// ...and whether that has finished. The mascot's idle clip waits for it:
    /// the clip carries a baked glow, and the arrival moves the character
    /// against a glow that is blooming in behind it.
    @State private var arrived = false

    /// How long the whole arrival takes. Driven flat, so each element's own
    /// slice of it runs at an even rate and the stagger reads as an order
    /// rather than as a rush and a straggler.
    private static let arrival = 1.25

    /// The character's slice of it: it starts falling here and has stopped
    /// bouncing by `dropFor` later.
    private static let dropAt = 0.10
    private static let dropFor = 0.52
    /// ...and the moment inside that slice when it first hits the floor,
    /// which is where `easeOutBounce` first touches: 1/2.75 of the way.
    private static let touchdown = dropAt + dropFor / 2.75
    /// The idle clip waits for the bouncing to finish, not for the screen:
    /// the character is moving throughout, so there is nothing to wait out.
    private static let mascotSettles = (dropAt + dropFor) * arrival

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
        .onAppear {
            guard entrance == 0 else { return }
            withAnimation(.linear(duration: Self.arrival)) { entrance = 1 }
            // The flag flips now and the fade it drives is what waits, so
            // the clip comes up under the character as it settles.
            withAnimation(.easeOut(duration: 0.3).delay(Self.mascotSettles)) {
                arrived = true
            }
        }
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

            // The order things arrive in, and what each one does on the way.
            // The light comes up first and the character drops into it; the
            // words follow from the top down; the bar, which is the thing you
            // are being asked to use, comes up from the bottom edge last.
            // The light comes up first and takes the hit when the character
            // lands on it.
            glow
                .ignite(entrance, impact: Self.touchdown)

            place(x: 0, y: 80, w: 393, h: 16) { greeting }
                .entrance(entrance, delay: 0.30, rise: 12)
            place(x: 60, y: 104, w: 273, h: 84) { question }
                .entrance(entrance, delay: 0.34, rise: 14)
            // The character does not rise into place, it is dropped into it
            // from 120pt up, lands hard enough to flatten by 16%, bounces
            // twice and settles. It is squashed against its own feet, which
            // is where the floor is. It falls before the words arrive, so
            // there is nothing above it to fall past.
            place(x: 0, y: 184, w: 393, h: 392) { mascot }
                .entrance(entrance,
                          delay: Self.dropAt, span: Self.dropFor,
                          drop: 120, anchor: MoodMascot.feet)
            // Up to size rather than sliding. It used to resolve out of a
            // 10pt blur as well, which was another offscreen pass during the
            // busiest second of the app's life for a touch nobody asked for.
            place(x: 0, y: 528, w: 393, h: 57) { moodLabel }
                .entrance(entrance, delay: 0.40, rise: 10, zoom: 0.22)
            place(x: 132, y: 588, w: 128.45, h: 49.45) { continueButton }
                .entrance(entrance, delay: 0.58, rise: 14, zoom: 0.10)
            place(x: 0, y: 699, w: 393, h: 30) { hint }
                .entrance(entrance, delay: 0.64, rise: 12)
            // The bar rises from the bottom edge as one piece; its five faces
            // pop in along it afterwards, which the bar handles itself.
            place(x: 0, y: 744, w: 393, h: BarLayout.frameHeight) {
                // The bar carries its own 5pt side inset, measured from its
                // frame, so it takes the full artboard width.
                MoodArcBar(progress: $progress, isDragging: $isDragging,
                           entrance: entrance)
            }
            .entrance(entrance, delay: 0.46, span: 0.32, rise: 56)
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
            // The blur, precomputed — see `Figma.glowStops`. Drawn as a blur
            // this was costing a full-screen Gaussian on every frame the
            // colour or the size changed, which is every frame of a drag and
            // of the arrival.
            RadialGradient(stops: Figma.glowStops(MoodScale.glow(at: progress)),
                           center: .center,
                           startRadius: 0,
                           endRadius: Figma.glowRadius)
                .frame(width: Figma.glowRadius * 2, height: Figma.glowRadius * 2)
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
        // A drum carrying all five words, turned by `progress` — see
        // `MoodWord`. It takes the position rather than the word, and each
        // word brings its own mood's colour, so there is no tint to set here.
        MoodWord(progress: progress)
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .animation(MoodMotion.follow(isDragging), value: progress)
    }

    /// The mascot. How one mood's drawing becomes the next is `MoodMascot`'s
    /// business; the screen supplies the position and the curve.
    private var mascot: some View {
        MoodMascot(progress: progress, isDragging: isDragging, arrived: arrived)
            .animation(MoodMotion.follow(isDragging), value: progress)
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
