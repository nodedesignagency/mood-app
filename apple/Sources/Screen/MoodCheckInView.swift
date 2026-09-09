import SwiftUI

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
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Pieces

    /// Paper with a soft bloom behind the character, tinted by the mood.
    private var backdrop: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(
                colors: [MoodScale.glow(at: progress), .clear],
                center: .init(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: 340
            )
            .animation(.easeOut(duration: 0.25), value: progress)
        }
        .ignoresSafeArea()
    }

    /// PLACEHOLDER for the rendered character.
    ///
    /// Drop `mascot-<key>` images into Assets and this picks them up. When the
    /// mascot videos land, swap this for a scrubbed `AVPlayer` layer driven off
    /// `progress` — the surrounding layout does not change.
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
                MoodFace(progress: progress, size: 190, color: MoodScale.accent(at: progress))
            }
        }
        .frame(maxWidth: 260, maxHeight: 260)
    }

    private var continueButton: some View {
        Button {
            // Wire to the next step in the flow.
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glass)
        .tint(.primary)
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
