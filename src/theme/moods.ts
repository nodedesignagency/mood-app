import { buildPalette, type Mood } from './palette';

export type { Mood };

/**
 * Dark scale — the v1 direction.
 *
 * Order matters: index 0 is the far-left end of the arc, index 4 the far
 * right. The selector exposes a *continuous* position rather than a discrete
 * choice, so every colour doubles as an interpolation keyframe.
 */
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

export const DARK_PALETTE = buildPalette(MOODS);

export const MOOD_COUNT = MOODS.length;
export const LAST_MOOD = DARK_PALETTE.last;

/** Kept as named exports because `lib/arc.ts` and v1 read them directly. */
export const MOOD_STOPS = DARK_PALETTE.stops;
export const DOT_COLORS = DARK_PALETTE.dot;
export const GLOW_COLORS = DARK_PALETTE.glow;
export const BG_COLORS = DARK_PALETTE.bg;
export const INK_COLORS = DARK_PALETTE.ink;
