# Artwork

The bar's faces. `genproj.py` picks up every `.png` under `Sources/` and copies
it into the app bundle, so `Image("name")` finds it by filename without the
extension — nothing to register by hand.

These came from "Mood 1 normal.png" … "Mood 5 blue.png" on the
`claude/curved-mood-selector-ui-n0zom2` branch, renamed off each mood's `key`
so they are found without a lookup table. Mood 1 is the saddest, Mood 5 the
happiest, which is the order the scale is already in.

| Mood | Resting | Selected (blue) |
| --- | --- | --- |
| Awful | `mood-awful.png` | `mood-awful-blue.png` |
| Low | `mood-low.png` | `mood-low-blue.png` |
| Okay | `mood-okay.png` | `mood-okay-blue.png` |
| Good | `mood-good.png` | `mood-good-blue.png` |
| Great | `mood-great.png` | `mood-great-blue.png` |

The names come from each mood's `key` in `Design/MoodScale.swift`, so they stay
in step if a mood is renamed.

Square, transparent, black for the resting face and #3169EC for the selected
one. The current set is 148px (132 for Okay), drawn into a 25.6pt frame, so
there is plenty of resolution to spare.

**They have to share an eye line.** The app centres each file's *canvas* in the
chip, so where a face appears is wherever the artist left it on that canvas —
and the eyes are what the viewer reads as the face's position, not the ink's
bounding box, which a drooping mouth or a wide grin changes. Awful and Great
arrived 1.04pt low and 0.52pt high against the other three and read as badly
spaced in the chip; both files were moved on their canvases to match. If any of
these are re-exported, check the eye rows land together — the fix belongs in
the Figma file, where the icons are not on a common baseline.

Until all ten are here the bar falls back to the faces drawn in
`Selector/MoodFace.swift`, so the app always runs.
