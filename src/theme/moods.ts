/**
 * The five moods the selector moves between.
 *
 * Order matters: index 0 is the far-left end of the arc, index 4 the far-right.
 * The selector exposes a *continuous* position (0 → 4) rather than a discrete
 * choice, so every colour below doubles as a keyframe that gets interpolated
 * while the thumb is travelling between two moods.
 */
export type Mood = {
  /** Stable id, safe to persist. */
  key: string;
  /** Display name, shown as the hero word. */
  label: string;
  /** One-line reading of the mood, shown under the hero word. */
  caption: string;
  /** Saturated colour for the track dot, mascot body and CTA. */
  dot: string;
  /** Colour of the soft bloom behind the mascot. */
  glow: string;
  /** Deep, near-black page background. */
  bg: string;
  /** Light tint used for text so it stays readable on `bg`. */
  ink: string;
};

export const MOODS: readonly Mood[] = [
  {
    key: 'awful',
    label: 'Awful',
    caption: 'Today is heavy. That’s allowed.',
    dot: '#FF3D8B',
    glow: '#FF2E88',
    bg: '#240A18',
    ink: '#FFC2DC',
  },
  {
    key: 'low',
    label: 'Low',
    caption: 'Running a little on empty.',
    dot: '#A97BFF',
    glow: '#7C4DFF',
    bg: '#170E2B',
    ink: '#D8C6FF',
  },
  {
    key: 'okay',
    label: 'Okay',
    caption: 'Somewhere in the middle.',
    dot: '#E9E6DE',
    glow: '#7A8394',
    bg: '#131418',
    ink: '#E9E6DE',
  },
  {
    key: 'good',
    label: 'Good',
    caption: 'Quietly doing alright.',
    dot: '#2FE0B0',
    glow: '#0FBF97',
    bg: '#04201C',
    ink: '#A8F5E0',
  },
  {
    key: 'great',
    label: 'Great',
    caption: 'Absolutely buzzing today.',
    dot: '#D7F13F',
    glow: '#B7DF1E',
    bg: '#1A2206',
    ink: '#ECFAA8',
  },
] as const;

export const MOOD_COUNT = MOODS.length;
export const LAST_MOOD = MOOD_COUNT - 1;

/**
 * Interpolation keyframes. `interpolateColor` needs plain arrays available to
 * the UI thread, so they are built once here instead of inside a worklet.
 */
export const MOOD_STOPS: number[] = MOODS.map((_, i) => i);
export const DOT_COLORS: string[] = MOODS.map((m) => m.dot);
export const GLOW_COLORS: string[] = MOODS.map((m) => m.glow);
export const BG_COLORS: string[] = MOODS.map((m) => m.bg);
export const INK_COLORS: string[] = MOODS.map((m) => m.ink);
