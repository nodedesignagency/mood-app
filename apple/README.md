# Mood — native iOS

SwiftUI, iOS 26+. Liquid Glass is used natively (`glassEffect`,
`GlassEffectContainer`), which is the reason this exists rather than the React
Native version in the repo root.

## Opening it

No extra tooling needed. In Xcode:

1. **File → New → Project → iOS → App.**
   Product Name `Mood`, Interface **SwiftUI**, Language **Swift**.
   Save it into this `apple/` folder.
2. Set the target's **Minimum Deployments** to **iOS 26.0**
   (target → General). Liquid Glass will not compile below that.
3. In the Project navigator, **delete the two files Xcode generated** —
   `MoodApp.swift` and `ContentView.swift` — choosing *Move to Trash*.
   Ours already has an `@main`, and two of them will not compile.
4. Drag the **`Sources` folder** from Finder into the project.
   Tick *Copy items if needed* **off**, and choose
   *Create groups* (or *Create folder references* — either works).
5. Pick your team under Signing & Capabilities, then run.

Sources live in `apple/Sources/`, deliberately not `apple/Mood/`, so Xcode's
template folder never collides with them.

### Optional: generate the project instead

`project.yml` is an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec, so
the `.xcodeproj` can be regenerated rather than checked in — worth it later to
stop project files conflicting in git. Needs Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install xcodegen
cd apple && xcodegen && open Mood.xcodeproj
```

## How the selector works

One continuous value, `progress`, runs 0 → 4 and is the only state. The bar,
the chip, the face, the hero word, the accent and the bloom all read from it,
so dragging blends between two moods rather than cutting between five.

`ArcGeometry.swift` carries the maths and explains the two-span trick and why
the curve is a symmetric quadratic. That part is ported from the React Native
version, where it was tuned against the reference tab bars.

## Placeholders to replace

Marked `PLACEHOLDER` in the source. These were read off the mockup images, not
from the Figma file:

| What | Where |
| --- | --- |
| Accent / glow colours per mood | `Design/MoodScale.swift` |
| Type sizes and weights | `Screen/MoodCheckInView.swift` |
| Bar thickness, chip size, arch depth | `ArcSpec` defaults in `ArcGeometry.swift` |
| Mascot art | `Assets` as `mascot-awful` … `mascot-great` |
| Mood icons | `Selector/MoodFace.swift` — swap for `Image(...)` |

## Mascot

Currently falls back to a drawn face if no `mascot-<key>` image is present, so
the screen runs before any asset exists. When the videos land, replace the
`mascot` property with a scrubbed `AVPlayer` driven off `progress`; nothing
around it needs to change.

## Haptics

`.sensoryFeedback` — a tick per crossing, firmer on settle. **Simulator has no
haptic hardware**; test on a device.
