import AVFoundation
import SwiftUI

/// A silent clip looping in place.
///
/// `AVQueuePlayer` with an `AVPlayerLooper` rather than a seek on an
/// end-of-item notification: the looper keeps the next pass already queued, so
/// the wrap is gapless. It needs to be, because the whole point of these clips
/// is that their last frame returns to their first.
///
/// Paused, the clip holds on frame 0, which is the mood's still — the frame
/// the screen would be showing anyway — so starting and stopping it is
/// invisible rather than a cut.
struct LoopingVideo: UIViewRepresentable {
    let url: URL
    /// False while a thumb is on the bar.
    var isPlaying: Bool

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.load(url)
        view.setPlaying(isPlaying)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.setPlaying(isPlaying)
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.stop()
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private let queue = AVQueuePlayer()
        private var looper: AVPlayerLooper?
        private var playing = false

        func load(_ url: URL) {
            queue.isMuted = true
            looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            playerLayer.player = queue
            // The clip is drawn in the box the still occupies, at the size the
            // still is drawn, so it must fit the same way the still does.
            playerLayer.videoGravity = .resizeAspect
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        func setPlaying(_ shouldPlay: Bool) {
            guard shouldPlay != playing else { return }
            playing = shouldPlay
            if shouldPlay {
                queue.play()
            } else {
                queue.pause()
                // Back to the still, so whatever is shown while a thumb is
                // down is the frame the rest of the screen expects.
                queue.seek(to: .zero)
            }
        }

        func stop() {
            queue.pause()
            looper?.disableLooping()
            looper = nil
            playerLayer.player = nil
        }
    }
}
