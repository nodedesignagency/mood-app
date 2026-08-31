/**
 * A mood scale and the interpolation keyframes derived from it.
 *
 * The selector's position is continuous (0 → last), so every colour below is
 * a keyframe rather than a fixed value: dragging between two moods blends
 * them. `interpolateColor` needs plain arrays reachable from the UI thread,
 * so a palette pre-flattens the mood list into one array per channel.
 */
export type Mood = {
  /** Stable id, safe to persist. */
  key: string;
  /** Display name, shown as the hero word. */
  label: string;
  /** One-line reading of the mood. */
  caption: string;
  /** Saturated colour: mascot body, knob core, CTA. */
  dot: string;
  /** Colour of the soft bloom behind the mascot. */
  glow: string;
  /** Page background. */
  bg: string;
  /** Text tint that stays readable on `bg`. */
  ink: string;
};

export type MoodPalette = {
  moods: readonly Mood[];
  /** Input range for every interpolation: [0, 1, … last]. */
  stops: number[];
  dot: string[];
  glow: string[];
  bg: string[];
  ink: string[];
  last: number;
};

export function buildPalette(moods: readonly Mood[]): MoodPalette {
  return {
    moods,
    stops: moods.map((_, i) => i),
    dot: moods.map((m) => m.dot),
    glow: moods.map((m) => m.glow),
    bg: moods.map((m) => m.bg),
    ink: moods.map((m) => m.ink),
    last: moods.length - 1,
  };
}
