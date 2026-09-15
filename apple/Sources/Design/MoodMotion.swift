import SwiftUI

/// The one curve this screen moves on.
///
/// The chip, the glow and the mood word's colour all follow `progress`, and
/// before they shared a curve they each had their own: the chip sprang, the
/// glow ran a 0.25-second ease-out, the word snapped.
///
/// An ease-out is the wrong shape for a value a thumb is driving. It cannot
/// be retargeted, so every touch event during a drag restarted it from
/// wherever it had got to — a hundred times a second, each one a fresh
/// quarter-second curve that never finished. That is what made the colour
/// lurch behind the thumb. A spring retargets from its current position *and*
/// velocity, so being interrupted constantly is the case it is built for.
enum MoodMotion {
    /// Tracking springs tight, so what follows the thumb feels welded to it;
    /// the release spring is looser and overshoots slightly, which is what
    /// gives the snap onto a mood its weight.
    static func follow(_ isDragging: Bool) -> Animation {
        isDragging
            ? .interactiveSpring(response: 0.20, dampingFraction: 0.86)
            : .spring(response: 0.42, dampingFraction: 0.62)
    }

    /// The mood word's entrance, and the exit of the word it replaces.
    ///
    /// The word is the one thing on this screen being *read*, so it does not
    /// ride `follow` with everything else. It arrives on the slower, looser
    /// of the two, with a little overshoot to settle on; the word it replaces
    /// leaves on the quicker one, and leaves without overshooting, so it is
    /// gone before it can be read as part of its replacement. Both drive one
    /// number per word — see `MoodWord`.
    static let wordEnter = Animation.spring(response: 0.40, dampingFraction: 0.74)
    static let wordExit = Animation.spring(response: 0.30, dampingFraction: 1)
}
