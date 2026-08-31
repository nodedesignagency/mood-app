# Mood

A daily mood check-in, built with Expo + React Native.

This repo currently contains one screen: the **mood selector**.

## The interaction

Five moods sit on a curved track at the bottom of the screen. You don't tap
them — you press anywhere on the track and slide your thumb. The knob travels
to your thumb, then follows it one-to-one; everything above (mascot, hero word,
background, CTA) re-tints continuously as you move. Let go and the knob
magnetises onto the nearest mood with a spring and a haptic thud.

The selector's position is a single continuous value, `progress`, running 0 → 4.
It lives on the UI thread as a Reanimated shared value, so the background,
bloom, mascot and knob all animate without a React render. Only the hero text
crosses back to JS, and only when the nearest mood actually changes.

## Why the track is a quadratic Bézier

The curve is symmetric: it starts and ends at the same height and sags in the
middle. Because the control point sits exactly halfway between the endpoints
horizontally, the x term collapses to a straight line — `x(t) = x0 + (x1-x0)·t`
— while y stays curved. So finger-x maps to track position with one divide: no
arc-length table, no Newton iteration per frame. Dots spaced evenly in `t` are
also spaced evenly in x, which is what the eye expects.

The track blob is that same path stroked at `TRACK_HEIGHT` with round caps.
One path, no separate outline geometry. See `src/lib/arc.ts`.

## Layout

```
src/
  lib/arc.ts               curve maths, shared by the gesture and the drawing
  lib/haptics.ts           fire-and-forget haptic helpers
  theme/moods.ts           the five moods + their colour keyframes
  theme/tokens.ts          type ramp, spacing, neutrals
  components/MoodArc.tsx   the curved track, dots, knob and pan gesture
  components/Mascot.tsx    placeholder mascot; every feature morphs with mood
  components/MoodBackdrop.tsx  mood-reactive background and radial bloom
  screens/MoodCheckInScreen.tsx
```

## The mascot is a placeholder

`Mascot.tsx` is assembled from primitives rather than an illustration, so the
face morphs *between* moods instead of cutting between five drawings. When the
real illustrated mascot lands it can keep the same two props (`progress`,
`pressed`) and reuse the interpolation curves already tuned here.

## Running it

```bash
npm install
npx expo start          # then scan the QR with Expo Go
```

Haptics need a physical device. `npx expo start --web` renders but has no
haptics and mouse-drag feel differs from thumb-drag.
