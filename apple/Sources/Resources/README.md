# Artwork

Drop the PNGs in this folder. Nothing else to do — `genproj.py` picks up every
`.png` under `Sources/` and copies it into the app bundle, so `Image("name")`
finds it by filename without the extension.

Ten files, named exactly like this:

| Mood | Resting | Selected (blue) |
| --- | --- | --- |
| Awful | `mood-awful.png` | `mood-awful-blue.png` |
| Low | `mood-low.png` | `mood-low-blue.png` |
| Okay | `mood-okay.png` | `mood-okay-blue.png` |
| Good | `mood-good.png` | `mood-good-blue.png` |
| Great | `mood-great.png` | `mood-great-blue.png` |

The names come from each mood's `key` in `Design/MoodScale.swift`, so they stay
in step if a mood is renamed.

Export them square, transparent, and at roughly 3× the size they are drawn —
the faces render at 25.6pt, so about 80px — or larger. They are drawn into a
fixed frame, so a bigger export only costs file size, never layout.

Until all ten are here the bar falls back to the faces drawn in
`Selector/MoodFace.swift`, so the app always runs.
