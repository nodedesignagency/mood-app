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
 * Which way the track curves and by how much.
 *
 * `depth` is in points, measured from the endpoints to the midpoint. It is
 * worth being conservative with: reference tab bars run a rise of only 3-5% of
 * their span, and anything much past that stops reading as a subtly curved bar
 * and starts reading as a banana.
 */
export type ArcShape = { bend: ArcBend; depth: number };

/** v1's smile, matching the emotion-slider reference it came from. */
export const VALLEY_SHAPE: ArcShape = { bend: VALLEY, depth: 30 };
/** v2's arch. ~4.7% of the travel span, in line with the tab-bar references. */
export const ARCH_SHAPE: ArcShape = { bend: HILL, depth: 13 };

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

/** Vertical padding so the knob can grow past the blob without clipping. */
export const ARC_PAD_V = 16;

export const KNOB_SIZE = 76;
export const DOT_SIZE = 13;
/** Emotion-icon stops are larger than colour chips - they carry detail. */
export const FACE_SIZE = 34;

/** Total height of the arc box for a given shape. */
export function arcHeight(shape: ArcShape): number {
  return ARC_PAD_V * 2 + TRACK_HEIGHT + shape.depth;
}

/**
 * Height of the curve's endpoints.
 *
 * An arch pushes its middle up, so its ends have to start lower to keep the
 * blob inside the box; a valley is the mirror image.
 */
export function arcYEnds(shape: ArcShape): number {
  'worklet';
  return shape.bend === HILL
    ? ARC_PAD_V + shape.depth + TRACK_HEIGHT / 2
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
export function arcY(t: number, shape: ArcShape): number {
  'worklet';
  return arcYEnds(shape) + shape.bend * 4 * shape.depth * t * (1 - t);
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
export function arcPath(width: number, shape: ArcShape): string {
  const x0 = ARC_INSET;
  const x1 = width - ARC_INSET;
  const yEnds = arcYEnds(shape);
  // A quadratic reaches only half way to its control point, so the control
  // sits at twice the depth to land the midpoint exactly on it.
  const ctrlY = yEnds + shape.bend * shape.depth * 2;
  return `M ${x0} ${yEnds} Q ${(x0 + x1) / 2} ${ctrlY} ${x1} ${yEnds}`;
}
