import { buildPalette, type Mood } from './palette';

/**
 * Light scale — the v2 direction.
 *
 * Hues run in one direction, indigo → gold, instead of jumping around the
 * wheel. That matters because the background is interpolated live while the
 * thumb moves: a ramp that reverses direction (red → blue → yellow) passes
 * through mud halfway between stops. Cool-to-warm also carries the meaning on
 * its own, low energy to high.
 *
 * `bg` is a pale wash of `dot` rather than the full colour, so ink-on-paper
 * text stays readable at every point on the scale; the saturation lives in the
 * bloom, the mascot and the knob.
 */
export const LIGHT_MOODS: readonly Mood[] = [
  {
    key: 'awful',
    label: 'Awful',
    caption: 'Today feels heavy. That’s allowed.',
    dot: '#6C63C7',
    glow: '#8078E0',
    bg: '#ECEAFA',
    ink: '#3B348A',
  },
  {
    key: 'low',
    label: 'Low',
    caption: 'Running a little on empty.',
    dot: '#4C9FDE',
    glow: '#6FB6EC',
    bg: '#E4F0FB',
    ink: '#1F5C8F',
  },
  {
    key: 'okay',
    label: 'Okay',
    caption: 'Somewhere in the middle.',
    dot: '#3FC9AE',
    glow: '#5FDCC2',
    bg: '#DFF6F0',
    ink: '#14705F',
  },
  {
    key: 'good',
    label: 'Good',
    caption: 'Quietly doing alright.',
    dot: '#8AD44B',
    glow: '#A3E068',
    bg: '#EDF8DC',
    ink: '#4A7A18',
  },
  {
    key: 'great',
    label: 'Great',
    caption: 'Absolutely buzzing today.',
    dot: '#FFC53D',
    glow: '#FFD469',
    bg: '#FFF3D8',
    ink: '#8A5B00',
  },
] as const;

export const LIGHT_PALETTE = buildPalette(LIGHT_MOODS);

/** Warm near-black used for outlines, faces and body copy. */
export const LIGHT_INK = '#1C1A16';
export const LIGHT_PAPER = '#FFFFFF';
