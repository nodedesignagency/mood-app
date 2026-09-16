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

**They all stand on one floor.** The four standing mascots landed their feet
within 3.1pt of each other as drawn, which is careful work. The melted one's
lowest pixel was 31.3pt above that line, so it floated. That was tolerable
while the mascot sat still; it is not once the character hops, because the hop
makes the floor something you can see it leave and land on. Awful has been
moved 97px down its canvas — 30.3pt as drawn — and all five now touch the same
floor to within 3.1pt.

If the set is ever re-exported, keep the lowest pixel of each drawing on a
common row. `MoodMascot` also takes the feet from it: stretch and squash are
anchored at 331 of the 392pt box, which is where that floor falls.

## The idle clips

`mascot-<key>.mp4` next to `mascot-<key>.png`, one per mood. All five have one
now. They stay optional in the code: a mood whose clip is missing keeps its
still and nothing else about the screen changes.

| Mood | Loop seam | Feet | Wander | Breath | Motion | Cut | Size |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Awful | 1.39 | 3.06pt | 0.77pt | 17.6pt | 1.394 | 16f | 852KB |
| Low | 1.31 | 0.00pt | 0.38pt | 6.1pt | 0.459 | 29f | 500KB |
| Okay | 1.14 | 0.00pt | 3.83pt | 13.8pt | 0.333 | 19f | 460KB |
| Good | 0.88 | 0.00pt | 0.77pt | 3.8pt | 0.317 | — | 565KB |
| Great | 0.88 | 0.00pt | 4.21pt | 13.0pt | 1.060 | — | 736KB |

Loop seam is the mean difference between the last frame and the first, out of
255; feet is how far the lowest ink moves across the clip; wander is the
horizontal travel of the character's centre; breath is the rise at the top;
motion is the mean frame-to-frame change. Every one of the five starts on a
frame that matches its still to 100% of the character's width with the feet
where they were.

They are generated from the still rather than drawn from nothing, which is the
whole reason they hold the character: the clip's **first frame is the app's own
rendering of that mood** — page, glow, rays and mascot, at the numbers in
`FigmaTokens` — and the same frame is given as both the start and the end
keyframe, which is what makes the loop seamless. Measured on the Okay clip:
the last frame differs from the first by 1.01/255 on average, the feet do not
move at all across the five seconds, and the colour does not drift.

**Cut the dead opening.** A generated clip tends to hold its first frame for
a beat before it starts moving, and that beat is spent exactly where it is most
visible: the moment you land on the mood. Low held for 1208ms, Okay for 792 and
Awful for 667, so all three are trimmed to where they actually wake up.

It costs almost nothing, because what is being cut is static. The new first
frame is still within 1/255 of the mood's still — closer, in fact, once
re-encoded — and the loop still closes, since the tail returns to a pose the new
head is only a hair from. Measure before cutting: find where the rolling
frame-to-frame motion first passes about 60% of the clip's own average, then
check the new first frame against the still and the new last-to-first seam.
Below about 8 frames it is not worth it; Good and Great wake in 6 and are left
alone.

Rules for any new one:

- Silent, and with **no audio track at all** — not a muted one — so playing it
  cannot duck or interrupt whatever the phone is already playing.
- 1176px square: 3× the 392pt box, which is as much as any iPhone can show.
- The feet stay on the floor, the character stays in its box, the camera never
  moves, and nothing new enters the frame.
- The glow is baked in, so the clip is only shown while the character is
  standing still. The hop would otherwise stretch that baked glow against the
  live one behind it.
- Awful, Low, Good and Great are lifted or lowered by `MoodMascot`'s posture:
  +7pt, +3.5, -3.5, -7, with Okay at 0. That offset moves the clip as well as
  the still, glow and all, so the glow in the first frame is rendered shifted
  the *other* way — it then lands back on the one the screen draws while the
  character ends up exactly where the still is. Okay needs none of this, which
  is why the first clip did not have it.
