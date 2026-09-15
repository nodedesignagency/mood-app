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

**Each face has to be centred on its own canvas.** The app centres a file's
*canvas* in the chip, so a face appears wherever the artist left it — and in
the set as exported, none of them were centred. Awful sat 1.56pt low in the
chip while the other four sat between 0.70 and 1.38pt high, which reads as
uneven padding, and it is the first thing anyone notices at this size.

All ten files have been moved on their canvases so the ink is centred both
ways; every face now sits within 0.19pt of the centre of its box. Nothing was
resized, and the resting and blue pairs were moved together so they still match
pixel for pixel.

Aligning the eyes instead was tried first and is wrong: the eye-to-mouth
distance differs by 0.86pt between these drawings, so eyes and mouth cannot
both be aligned by moving a face, and putting the eyes on one line leaves the
face itself off-centre in the chip by up to 1pt.

What is left cannot be fixed by moving anything. The drawings are not
consistent with each other: the stroke weight varies by 14% (Awful and Low are
drawn heavier than Good and Great), the mouths by 20% (Great's grin is the
widest), and Okay is on a 132px canvas where the rest are 148px, which quietly
scales it up 12%. If these are ever redrawn, that is what to fix, in the Figma
file.

## The mascot

One per mood, `mascot-awful.png` … `mascot-great.png`, named off each mood's
`key` exactly as the faces are. They came from `image-Photoroom (75)` and
`(88)`–`(91)` on the `claude/curved-mood-selector-ui-n0zom2` branch, where they
were uploaded under those names; which is which was settled by hue, and the
five fall in the scale's own order — red, purple, blue, green, orange — with
the expressions agreeing (the red one has melted, the orange one is wearing
sunglasses).

| Mood | File | From |
| --- | --- | --- |
| Awful | `mascot-awful.png` | `image-Photoroom (90)` |
| Low | `mascot-low.png` | `image-Photoroom (91)` |
| Okay | `mascot-okay.png` | `image-Photoroom (75)` |
| Good | `mascot-good.png` | `image-Photoroom (88)` |
| Great | `mascot-great.png` | `image-Photoroom (89)` |

1254px square, transparent, drawn into a 392pt box on the artboard.

**Awful does not stand on the same floor as the rest.** The four standing
mascots land their feet within 3.1pt of each other, which is careful work. The
melted one's lowest pixel is 31.3pt above that line, so it floats rather than
lying on the floor the others stand on. Whether that is wanted is a design
call, not a bug to be patched here — if it should sit on the floor, the fix is
to move it down its canvas, the way the faces were.
