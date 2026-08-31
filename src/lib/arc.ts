import { LAST_MOOD } from '../theme/moods';

/**
 * Geometry for the curved mood track.
 *
 * The track is a symmetric quadratic Bézier: it starts and ends at the same
 * height and sags in the middle, giving the smile-shaped groove the thumb
 * rides along.
 *
 *   P0 = (x0, yEnds)   P1 = (midX, yEnds + 2·SAG)   P2 = (x1, yEnds)
 *
 * Because P1 sits exactly halfway between P0 and P2 horizontally, the x term
 * collapses to a straight line:
 *
 *   x(t) = (1-t)²·x0 + 2t(1-t)·midX + t²·x1  ≡  x0 + (x1 - x0)·t
 *
 * That is the whole reason this shape was chosen. It means finger-x maps to
 * curve position `t` with a plain linear divide — no arc-length lookup table,
 * no Newton iteration — while y still bends. Dots spaced evenly in `t` are
 * therefore also spaced evenly in x, exactly as the eye expects.
 *
 * The y term keeps the quadratic and simplifies to a tidy parabola:
 *
 *   y(t) = yEnds ± 4·BEND·t(1-t)     → y(0)=y(1)=yEnds, y(0.5)=yEnds±BEND
 *
 * The sign is the `bend` argument threaded through everything below:
 *
 *   bend = HILL   the middle rises above the ends — an arch, like a floating
 *                 tab bar. The ends therefore have to sit lower in the box.
 *   bend = VALLEY the middle sags below the ends — a smile.
 *
 * Both shapes occupy exactly the same box height, so a screen can swap between
 * them without re-laying anything out.
 */

/** The middle of the curve rises above its ends. */
export const HILL = -1;
/** The middle of the curve sags below its ends. */
export const VALLEY = 1;
export type ArcBend = typeof HILL | typeof VALLEY;

/**
 * Horizontal breathing room between the arc box and the ends of the curve.
 *
 * Must clear half the track thickness plus half the knob at its pressed scale,
 * otherwise the blob's rounded cap, the knob, or its selection ring get clipped
 * at either extreme. The blob still reaches within ~14pt of the screen edge,
 * because its rounded cap extends half the track height past the curve's end.
 */
export const ARC_INSET = 58;
/** Thickness of the blob the curve is stroked into. */
export const TRACK_HEIGHT = 88;
/** How far the middle of the curve departs from its ends, in either direction. */
export const ARC_BEND = 30;
/** Vertical padding so the knob can grow past the blob without clipping. */
export const ARC_PAD_V = 16;

export const KNOB_SIZE = 76;
export const DOT_SIZE = 13;
/** Emotion-icon stops are larger than colour chips - they carry detail. */
export const FACE_SIZE = 34;

/** Total height of the arc box. Identical for both bends. */
export const ARC_HEIGHT = ARC_PAD_V * 2 + TRACK_HEIGHT + ARC_BEND;

/**
 * Height of the curve's endpoints.
 *
 * An arch pushes its middle up, so its ends have to start lower to keep the
 * blob inside the box; a valley is the mirror image.
 */
export function arcYEnds(bend: ArcBend): number {
  'worklet';
  return bend === HILL
    ? ARC_PAD_V + ARC_BEND + TRACK_HEIGHT / 2
    : ARC_PAD_V + TRACK_HEIGHT / 2;
}

/** Left edge of the curve. */
export function arcStartX(): number {
  'worklet';
  return ARC_INSET;
}

/** Right edge of the curve, given the arc box width. */
export function arcEndX(width: number): number {
  'worklet';
  return width - ARC_INSET;
}

/** Curve position `t` (0…1) → x, in arc-box coordinates. */
export function arcX(t: number, width: number): number {
  'worklet';
  return ARC_INSET + (width - ARC_INSET * 2) * t;
}

/** Curve position `t` (0…1) → y, in arc-box coordinates. */
export function arcY(t: number, bend: ArcBend): number {
  'worklet';
  return arcYEnds(bend) + bend * 4 * ARC_BEND * t * (1 - t);
}

/** Finger x → curve position `t`, clamped to the ends of the track. */
export function xToT(x: number, width: number): number {
  'worklet';
  const span = width - ARC_INSET * 2;
  if (span <= 0) return 0;
  const t = (x - ARC_INSET) / span;
  return t < 0 ? 0 : t > 1 ? 1 : t;
}

/** Curve position `t` (0…1) ⇄ continuous mood index (0…4). */
export function tToMood(t: number): number {
  'worklet';
  return t * LAST_MOOD;
}

export function moodToT(index: number): number {
  'worklet';
  return index / LAST_MOOD;
}

/** SVG path for the curve. Stroking it thickly *is* the track blob. */
export function arcPath(width: number, bend: ArcBend): string {
  const x0 = ARC_INSET;
  const x1 = width - ARC_INSET;
  const yEnds = arcYEnds(bend);
  // A quadratic reaches only half way to its control point, so the control
  // sits at twice the bend to land the midpoint exactly on it.
  const ctrlY = yEnds + bend * ARC_BEND * 2;
  return `M ${x0} ${yEnds} Q ${(x0 + x1) / 2} ${ctrlY} ${x1} ${yEnds}`;
}
