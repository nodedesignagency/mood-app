import { LAST_MOOD } from '../theme/moods';

/**
 * Geometry for the curved mood track.
 *
 * The track is a symmetric quadratic Bézier: it starts and ends at the same
 * height and bends in the middle, giving the groove the thumb rides along.
 * Because the control point sits exactly halfway between the endpoints
 * horizontally, the x term collapses to a straight line:
 *
 *   x(t) = (1-t)²·x0 + 2t(1-t)·midX + t²·x1  ≡  x0 + (x1 - x0)·t
 *
 * That is the whole reason this shape was chosen. Finger-x maps to curve
 * position with a plain linear divide — no arc-length table, no Newton
 * iteration — while y still bends, and evenly spaced stops stay evenly spaced
 * on screen. The y term stays quadratic and reduces to a parabola.
 *
 * Two spans matter, and they are not the same one:
 *
 *   blobInset    where the drawn bar starts and ends
 *   travelInset  where the knob and the stops start and end
 *
 * The knob is wider than the bar's rounded cap, so if the two spans matched,
 * the knob at either extreme would hang off the end of the bar. Letting the
 * bar run wider than the travel keeps the knob inside it horizontally while
 * still overhanging it vertically — which is the whole look.
 */

/** The middle of the curve rises above its ends. */
export const HILL = -1;
/** The middle of the curve sags below its ends. */
export const VALLEY = 1;
export type ArcBend = typeof HILL | typeof VALLEY;

/** How much the knob grows while a thumb is on it. */
export const PRESS_SCALE = 1.08;

export type ArcShape = {
  bend: ArcBend;
  /**
   * Rise (or sag) from the bar's endpoints to its midpoint, in points.
   *
   * Note this is measured across the *bar*, not across the travel. When the
   * travel is inset from the bar it only sees the middle of the parabola, so
   * the arch the user actually reads is shallower than this number.
   */
  depth: number;
  /** Thickness of the blob the curve is stroked into. */
  track: number;
  /** Where the drawn bar begins, from the edge of the box. */
  blobInset: number;
  /** Where the knob and stops begin. Must clear half the knob's pressed width. */
  travelInset: number;
};

/** v1's smile. Bar and travel share a span, as its knob fits inside the cap. */
export const VALLEY_SHAPE: ArcShape = {
  bend: VALLEY,
  depth: 30,
  track: 88,
  blobInset: 58,
  travelInset: 58,
};

/**
 * v2's arch: a thin bar the selected chip rides proud of.
 *
 * `depth` is 20 across the bar, but the travel is inset from the bar's ends,
 * so the rise across the part the thumb actually covers works out at ~13pt on
 * a ~270pt span — about 4.8%, in line with the tab-bar references.
 */
export const ARCH_SHAPE: ArcShape = {
  bend: HILL,
  depth: 20,
  track: 58,
  blobInset: 30,
  travelInset: 60,
};

/** Vertical breathing room above and below whatever reaches furthest. */
export const ARC_PAD_V = 14;

export const KNOB_SIZE = 76;
export const DOT_SIZE = 13;
/** Emotion-icon stops are larger than colour chips — they carry detail. */
export const FACE_SIZE = 34;

/** Everything drawing and gesture need, resolved once per layout. */
export type ArcGeometry = {
  bend: ArcBend;
  depth: number;
  track: number;
  width: number;
  blobInset: number;
  travelInset: number;
  /** Height of the bar's endpoints within the box. */
  yEnds: number;
  /** Total height of the arc box. */
  height: number;
};

/**
 * Size the box around the curve.
 *
 * The knob may be taller than the track — that overhang is what makes the
 * selected chip read as riding proud of the bar rather than sunk into it — so
 * the box is sized by whichever of the two reaches further from the curve.
 */
export function arcGeometry(
  shape: ArcShape,
  knobHeight: number,
  width: number,
): ArcGeometry {
  const reach = Math.max(shape.track, knobHeight * PRESS_SCALE) / 2;
  return {
    bend: shape.bend,
    depth: shape.depth,
    track: shape.track,
    width,
    blobInset: shape.blobInset,
    travelInset: shape.travelInset,
    // An arch pushes its middle up, so its ends must start lower to stay in
    // the box; a valley is the mirror image.
    yEnds: ARC_PAD_V + reach + (shape.bend === HILL ? shape.depth : 0),
    height: ARC_PAD_V * 2 + shape.depth + reach * 2,
  };
}

/** Travel position `u` (0…1) → x, in arc-box coordinates. */
export function arcX(u: number, geo: ArcGeometry): number {
  'worklet';
  return geo.travelInset + (geo.width - geo.travelInset * 2) * u;
}

/** Travel position `u` (0…1) → y, following the bar's own parabola. */
export function arcY(u: number, geo: ArcGeometry): number {
  'worklet';
  const barSpan = geo.width - geo.blobInset * 2;
  if (barSpan <= 0) return geo.yEnds;
  // Re-express the travel position along the bar before evaluating the curve,
  // so stops sit on the drawn centreline rather than on a curve of their own.
  const t = (arcX(u, geo) - geo.blobInset) / barSpan;
  return geo.yEnds + geo.bend * 4 * geo.depth * t * (1 - t);
}

/** Finger x → travel position `u`, clamped to the ends of the travel. */
export function xToU(x: number, geo: ArcGeometry): number {
  'worklet';
  const span = geo.width - geo.travelInset * 2;
  if (span <= 0) return 0;
  const u = (x - geo.travelInset) / span;
  return u < 0 ? 0 : u > 1 ? 1 : u;
}

/** Travel position `u` (0…1) ⇄ continuous mood index (0…4). */
export function uToMood(u: number): number {
  'worklet';
  return u * LAST_MOOD;
}

/** SVG path for the bar. Stroking it thickly *is* the blob. */
export function arcPath(geo: ArcGeometry): string {
  const x0 = geo.blobInset;
  const x1 = geo.width - geo.blobInset;
  // A quadratic reaches only half way to its control point, so the control
  // sits at twice the depth to land the midpoint exactly on it.
  const ctrlY = geo.yEnds + geo.bend * geo.depth * 2;
  return `M ${x0} ${geo.yEnds} Q ${(x0 + x1) / 2} ${ctrlY} ${x1} ${geo.yEnds}`;
}
