import { StyleSheet, Text, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  Extrapolation,
  interpolate,
  interpolateColor,
  runOnJS,
  useAnimatedReaction,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Path } from 'react-native-svg';
import { LinearGradient } from 'expo-linear-gradient';

import {
  ARC_INSET,
  DOT_SIZE,
  FACE_SIZE,
  KNOB_SIZE,
  TRACK_HEIGHT,
  VALLEY_SHAPE,
  arcHeight,
  arcPath,
  arcX,
  arcY,
  tToMood,
  xToT,
  type ArcShape,
} from '../lib/arc';
import { DARK_PALETTE } from '../theme/moods';
import type { MoodPalette } from '../theme/palette';
import { CAPS, NEUTRAL } from '../theme/tokens';
import { MoodFace, MoodFaceLive } from './MoodFace';

/**
 * Everything that differs between the dark v1 and the light v2. The gesture,
 * the geometry and the snapping behaviour are identical, so only paint is
 * parameterised.
 */
export type ArcSkin = {
  /** Fill of the track blob. */
  track: string;
  /** Hairline rim drawn just outside the blob. */
  rim: string;
  /** How far the rim extends past the blob. A wide soft rim fakes a shadow. */
  rimWidth: number;
  /** Dotted line threading the stops together. */
  guide: string;
  /** Fill of the knob disc. */
  knobFace: string;
  knobBorder: string;
  /** Tint the whole disc with the mood colour instead of an inner chip. */
  tintKnob: boolean;
  /** Size and corner of the selected element. */
  knob: { width: number; height: number; radius: number };
  /**
   * Give the selected element the raised-glass treatment: a bright bevel down
   * the top, a shadow underneath, a light rim. Modelled on iOS's selected
   * segment, which reads as a lozenge floating above the track rather than a
   * flat fill sitting in it.
   */
  glass: boolean;
  /** Ink used for the emotion faces, when `stops` is 'faces'. */
  faceInk: string;
  /** Coloured dots (v1) or emotion icons (v2). */
  stops: 'dots' | 'faces';
  /** The Awful / Great captions above the ends. Redundant once faces show. */
  endCaps: boolean;
  /** Drop shadow under the blob. Reads on light backgrounds, not on dark. */
  raised: boolean;
};

export const DARK_SKIN: ArcSkin = {
  track: 'rgba(255,255,255,0.07)',
  rim: 'rgba(255,255,255,0.14)',
  rimWidth: 2,
  guide: 'rgba(255,255,255,0.20)',
  knobFace: '#1B1C21',
  knobBorder: 'rgba(255,255,255,0.22)',
  tintKnob: false,
  knob: { width: KNOB_SIZE, height: KNOB_SIZE, radius: KNOB_SIZE / 2 },
  glass: false,
  faceInk: '#1C1A16',
  stops: 'dots',
  endCaps: true,
  raised: false,
};

/** Quick, eager spring that carries the knob to a finger placed away from it. */
const GRAB_SPRING = { damping: 20, stiffness: 260, mass: 0.7 } as const;
/** Softer spring with a touch of overshoot for the magnetic snap on release. */
const SETTLE_SPRING = { damping: 15, stiffness: 170, mass: 0.9 } as const;

type Props = {
  /** Continuous mood position, 0 → 4. Owned by the screen, driven from here. */
  progress: SharedValue<number>;
  /** 1 while a thumb is down. */
  pressed: SharedValue<number>;
  /** Usable width of the arc box. */
  width: number;
  /** Fires whenever the nearest mood changes, mid-drag included. */
  onCross: (index: number) => void;
  /** Fires once the knob has snapped after release. */
  onSettle: (index: number) => void;
  /** Mood scale to render. Defaults to the dark v1 scale. */
  palette?: MoodPalette;
  /** Paint. Defaults to the dark v1 skin. */
  skin?: ArcSkin;
  /** Which way the track curves and how deep. Defaults to v1's valley. */
  shape?: ArcShape;
};

export function MoodArc({
  progress,
  pressed,
  width,
  onCross,
  onSettle,
  palette = DARK_PALETTE,
  skin = DARK_SKIN,
  shape = VALLEY_SHAPE,
}: Props) {
  const { stops: MOOD_STOPS, dot: DOT_COLORS, moods: MOODS, last: LAST_MOOD } = palette;
  const height = arcHeight(shape);
  const knobW = skin.knob.width;
  const knobH = skin.knob.height;
  /** Raw finger position, in mood units. */
  const finger = useSharedValue(0);
  /**
   * Distance between the knob and the finger at the moment of touch-down,
   * sprung back to zero. This is what makes the knob *travel* to a thumb
   * placed somewhere else on the track instead of teleporting under it.
   */
  const grabOffset = useSharedValue(0);
  const dragging = useSharedValue(false);
  /** Nearest mood last reported, so a crossing only fires once. */
  const lastCrossed = useSharedValue(-1);

  // While a drag is live the knob follows the finger plus the decaying offset.
  // On release this stops firing and the settle spring owns `progress` again.
  useAnimatedReaction(
    () => ({
      target: finger.value + grabOffset.value,
      live: dragging.value,
    }),
    ({ target, live }) => {
      if (live) progress.value = target;
    },
  );

  // Report crossings from `progress` itself, so the grab spring and the settle
  // spring tick too — not just raw finger movement.
  useAnimatedReaction(
    () => Math.round(progress.value),
    (index, previous) => {
      if (previous !== null && index !== lastCrossed.value) {
        lastCrossed.value = index;
        runOnJS(onCross)(index);
      }
    },
  );

  const pan = Gesture.Pan()
    // Activate on touch-down rather than after a drag threshold: the whole
    // point is press-and-move, so there is nothing to disambiguate against.
    .minDistance(0)
    // Thumbs wander off a 92pt-tall track constantly; never drop the drag.
    .shouldCancelWhenOutside(false)
    .hitSlop({ top: 24, bottom: 44, left: 0, right: 0 })
    .onBegin((e) => {
      const target = tToMood(xToT(e.x, width));
      finger.value = target;
      grabOffset.value = progress.value - target;
      dragging.value = true;
      grabOffset.value = withSpring(0, GRAB_SPRING);
      pressed.value = withTiming(1, { duration: 110 });
    })
    .onUpdate((e) => {
      finger.value = tToMood(xToT(e.x, width));
    })
    .onFinalize(() => {
      dragging.value = false;
      pressed.value = withTiming(0, { duration: 240 });
      const snapped = Math.min(LAST_MOOD, Math.max(0, Math.round(progress.value)));
      progress.value = withSpring(snapped, SETTLE_SPRING);
      runOnJS(onSettle)(snapped);
    });

  const knob = useAnimatedStyle(() => {
    const t = progress.value / LAST_MOOD;
    return {
      transform: [
        { translateX: arcX(t, width) - knobW / 2 },
        { translateY: arcY(t, shape) - knobH / 2 },
        { scale: 1 + pressed.value * 0.08 },
      ],
    };
  });

  const knobCore = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
    transform: [{ scale: 1 + pressed.value * 0.18 }],
  }));

  const knobDisc = useAnimatedStyle(() => ({
    backgroundColor: skin.tintKnob
      ? interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS)
      : skin.knobFace,
  }));

  const knobRing = useAnimatedStyle(() => ({
    borderColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
    opacity: pressed.value * 0.55,
    transform: [{ scale: 1 + pressed.value * 0.26 }],
  }));

  const d = arcPath(width, shape);

  return (
    <View style={{ width }}>
      {skin.endCaps ? (
        <View style={styles.caps}>
          <Text style={styles.capLabel}>{MOODS[0].label}</Text>
          <Text style={styles.capLabel}>{MOODS[LAST_MOOD].label}</Text>
        </View>
      ) : null}

      <GestureDetector gesture={pan}>
        <View style={[styles.stage, { width, height }]}>
          <Svg width={width} height={height} pointerEvents="none">
            {/* Stroking the curve *is* the track: one path, rounded caps,
                thickness = the blob's height. The slightly fatter pass
                underneath leaves a hairline rim. */}
            <Path
              d={d}
              stroke={skin.rim}
              strokeWidth={TRACK_HEIGHT + skin.rimWidth}
              strokeLinecap="round"
              fill="none"
            />
            <Path
              d={d}
              stroke={skin.track}
              strokeWidth={TRACK_HEIGHT}
              strokeLinecap="round"
              fill="none"
            />
            {/* Dotted guide threading the five stops together. */}
            <Path
              d={d}
              stroke={skin.guide}
              strokeWidth={2}
              strokeLinecap="round"
              strokeDasharray="0.1 8"
              fill="none"
            />
          </Svg>

          {MOODS.map((mood, i) => (
            <Stop
              key={mood.key}
              index={i}
              progress={progress}
              width={width}
              color={skin.stops === 'faces' ? skin.faceInk : mood.dot}
              kind={skin.stops}
              last={LAST_MOOD}
              shape={shape}
            />
          ))}

          <Animated.View style={[styles.knob, knob]} pointerEvents="none">
            <Animated.View style={[styles.knobRing, knobRing]} />
            <Animated.View
              style={[
                styles.knobFace,
                {
                  width: knobW,
                  height: knobH,
                  borderRadius: skin.knob.radius,
                  borderColor: skin.knobBorder,
                },
                skin.raised && styles.knobRaised,
                knobDisc,
              ]}
            >
              {skin.glass ? (
                // Bevel: bright down the top third, neutral through the middle,
                // barely darkened at the base. That vertical fall-off is what
                // makes a flat fill read as a raised, lit surface.
                <LinearGradient
                  colors={[
                    'rgba(255,255,255,0.55)',
                    'rgba(255,255,255,0.10)',
                    'rgba(0,0,0,0.10)',
                  ]}
                  locations={[0, 0.48, 1]}
                  style={[StyleSheet.absoluteFill, { borderRadius: skin.knob.radius }]}
                  pointerEvents="none"
                />
              ) : null}
              {skin.stops === 'faces' ? (
                // The knob wears the expression it is currently between, so the
                // face morphs under the thumb rather than cutting between five.
                <MoodFaceLive progress={progress} size={44} color={skin.faceInk} />
              ) : (
                <Animated.View style={[styles.knobCore, knobCore]} />
              )}
            </Animated.View>
          </Animated.View>
        </View>
      </GestureDetector>
    </View>
  );
}

/**
 * One stop on the track: a colour chip (v1) or an emotion face (v2).
 *
 * It fades and shrinks as the knob arrives, so the knob reads as picking the
 * stop up rather than parking on top of it.
 */
function Stop({
  index,
  progress,
  width,
  color,
  kind,
  last,
  shape,
}: {
  index: number;
  progress: SharedValue<number>;
  width: number;
  color: string;
  kind: 'dots' | 'faces';
  last: number;
  shape: ArcShape;
}) {
  const size = kind === 'faces' ? FACE_SIZE : DOT_SIZE;
  const t = index / last;
  const left = arcX(t, width) - size / 2;
  const top = arcY(t, shape) - size / 2;

  const style = useAnimatedStyle(() => {
    const distance = Math.abs(progress.value - index);
    return {
      opacity: interpolate(distance, [0, 0.55, 1.2], [0, 0.5, 1], Extrapolation.CLAMP),
      transform: [
        { scale: interpolate(distance, [0, 0.55, 1.2], [0.3, 0.8, 1], Extrapolation.CLAMP) },
      ],
    };
  });

  return (
    <Animated.View
      pointerEvents="none"
      style={[{ position: 'absolute', left, top }, style]}
    >
      {kind === 'faces' ? (
        <MoodFace index={index} size={FACE_SIZE} color={color} />
      ) : (
        <View style={[styles.dot, { backgroundColor: color }]} />
      )}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  caps: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: ARC_INSET - 6,
    marginBottom: 12,
  },
  capLabel: { ...CAPS, color: NEUTRAL.dim },
  stage: { position: 'relative' },
  dot: { width: DOT_SIZE, height: DOT_SIZE, borderRadius: DOT_SIZE / 2 },
  knob: { position: 'absolute', top: 0, left: 0, alignItems: 'center', justifyContent: 'center' },
  knobRing: {
    position: 'absolute',
    width: KNOB_SIZE,
    height: KNOB_SIZE,
    borderRadius: KNOB_SIZE / 2,
    borderWidth: 2,
  },
  knobFace: {
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOpacity: 0.45,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 10 },
    elevation: 12,
  },
  knobRaised: {
    shadowOpacity: 0.18,
    shadowRadius: 14,
    shadowOffset: { width: 0, height: 6 },
  },
  knobCore: { width: 34, height: 34, borderRadius: 17 },
});
