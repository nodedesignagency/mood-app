# Mood — native iOS

SwiftUI, iOS 26+. Liquid Glass is used natively (`glassEffect`,
`GlassEffectContainer`), which is the reason this exists rather than the React
Native version in the repo root.

## Opening it

```bash
brew install xcodegen
cd apple && xcodegen        # generates Mood.xcodeproj
open Mood.xcodeproj
```

The project file is generated, not checked in, so it never conflicts in git and
never drifts from the files on disk. If you'd rather not install XcodeGen:
File → New → Project → iOS App (SwiftUI), target iOS 26, then drag the `Mood`
folder in.

Set `DEVELOPMENT_TEAM` in `project.yml`, or just pick your team in Xcode's
Signing tab.

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
