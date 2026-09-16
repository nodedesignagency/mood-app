import AVFoundation
import SwiftUI

/// A silent clip looping in place.
///
/// `AVQueuePlayer` with an `AVPlayerLooper` rather than a seek on an
/// end-of-item notification: the looper keeps the next pass already queued, so
/// the wrap is gapless. It needs to be, because the whole point of these clips
/// is that their last frame returns to their first.
///
/// The view stays alive whether or not there is anything to play, and a `nil`
/// url pauses it rather than tearing it down. That is not tidiness — it is the
/// difference between the character coming alive the moment you land on its
/// mood and taking a visible beat to do it. Built and thrown away as the mood
/// changed, every arrival paid for an `AVPlayerItem`, the asset being opened
/// and a looper being wired up before the first frame could run.
struct LoopingVideo: UIViewRepresentable {
    /// The clip to loop, or nil for a mood that has none. It runs whenever
    /// there is one: there is no separate "playing" to get wrong, and
    /// something already rolling has nothing to start.
    let url: URL?

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.show(url)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.show(url)
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.stop()
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private let queue = AVQueuePlayer()
        private var looper: AVPlayerLooper?
        private var loaded: URL?
        private var playing = false

        override init(frame: CGRect) {
            super.init(frame: frame)
            queue.isMuted = true
            // These are local files. Left on, this holds playback back while
            // it decides whether enough is buffered — a wait worth having for
            // a stream and pure latency for a half-megabyte clip in the app.
            queue.automaticallyWaitsToMinimizeStalling = false
            playerLayer.player = queue
            // The clip is drawn in the box the still occupies, at the size the
            // still is drawn, so it has to fit the same way the still does.
            playerLayer.videoGravity = .resizeAspect
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not from a nib") }

        /// Run this mood's clip, or hold.
        ///
        /// A mood with no clip pauses what is loaded rather than unloading
        /// it. Dragging off a mood and coming back to it is the common move
        /// on this screen, and tearing the item down means rebuilding it on
        /// the way back — the delay this whole file exists to avoid. Loading
        /// the clip that is already loaded does nothing at all.
        ///
        /// Nothing seeks back to the start, either. The clip is hidden before
        /// it is held, so where it rests is not on screen, and a loop picked
        /// up where it left off is still a loop.
        func show(_ url: URL?) {
            guard let url else {
                if playing { queue.pause(); playing = false }
                return
            }
            if url != loaded {
                loaded = url
                looper?.disableLooping()
                queue.removeAllItems()
                looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            }
            if !playing { queue.play(); playing = true }
        }

        func stop() {
            queue.pause()
            looper?.disableLooping()
            looper = nil
            queue.removeAllItems()
            playerLayer.player = nil
        }
    }
}
