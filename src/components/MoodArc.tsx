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

import {
  ARC_HEIGHT,
  ARC_INSET,
  DOT_SIZE,
  KNOB_SIZE,
  TRACK_HEIGHT,
  arcPath,
  arcX,
  arcY,
  moodToT,
  tToMood,
  xToT,
} from '../lib/arc';
import { DOT_COLORS, LAST_MOOD, MOODS, MOOD_STOPS } from '../theme/moods';
import { CAPS, NEUTRAL } from '../theme/tokens';

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
};

export function MoodArc({ progress, pressed, width, onCross, onSettle }: Props) {
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
        { translateX: arcX(t, width) - KNOB_SIZE / 2 },
        { translateY: arcY(t) - KNOB_SIZE / 2 },
        { scale: 1 + pressed.value * 0.08 },
      ],
    };
  });

  const knobCore = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
    transform: [{ scale: 1 + pressed.value * 0.18 }],
  }));

  const knobRing = useAnimatedStyle(() => ({
    borderColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
    opacity: pressed.value * 0.55,
    transform: [{ scale: 1 + pressed.value * 0.26 }],
  }));

  const d = arcPath(width);

  return (
    <View style={{ width }}>
      <View style={styles.caps}>
        <Text style={styles.capLabel}>{MOODS[0].label}</Text>
        <Text style={styles.capLabel}>{MOODS[LAST_MOOD].label}</Text>
      </View>

      <GestureDetector gesture={pan}>
        <View style={[styles.stage, { width, height: ARC_HEIGHT }]}>
          <Svg width={width} height={ARC_HEIGHT} pointerEvents="none">
            {/* Stroking the curve *is* the track: one path, rounded caps,
                thickness = the blob's height. The slightly fatter pass
                underneath leaves a hairline rim. */}
            <Path
              d={d}
              stroke="rgba(255,255,255,0.14)"
              strokeWidth={TRACK_HEIGHT + 2}
              strokeLinecap="round"
              fill="none"
            />
            <Path
              d={d}
              stroke="rgba(255,255,255,0.07)"
              strokeWidth={TRACK_HEIGHT}
              strokeLinecap="round"
              fill="none"
            />
            {/* Dotted guide threading the five stops together. */}
            <Path
              d={d}
              stroke="rgba(255,255,255,0.20)"
              strokeWidth={2}
              strokeLinecap="round"
              strokeDasharray="0.1 8"
              fill="none"
            />
          </Svg>

          {MOODS.map((mood, i) => (
            <Dot key={mood.key} index={i} progress={progress} width={width} color={mood.dot} />
          ))}

          <Animated.View style={[styles.knob, knob]} pointerEvents="none">
            <Animated.View style={[styles.knobRing, knobRing]} />
            <View style={styles.knobFace}>
              <Animated.View style={[styles.knobCore, knobCore]} />
            </View>
          </Animated.View>
        </View>
      </GestureDetector>
    </View>
  );
}

/**
 * One stop on the track. It fades and shrinks as the knob arrives so the knob
 * reads as picking the dot up rather than covering it.
 */
function Dot({
  index,
  progress,
  width,
  color,
}: {
  index: number;
  progress: SharedValue<number>;
  width: number;
  color: string;
}) {
  const t = moodToT(index);
  const left = arcX(t, width) - DOT_SIZE / 2;
  const top = arcY(t) - DOT_SIZE / 2;

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
      style={[styles.dot, { left, top, backgroundColor: color }, style]}
    />
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
  dot: {
    position: 'absolute',
    width: DOT_SIZE,
    height: DOT_SIZE,
    borderRadius: DOT_SIZE / 2,
  },
  knob: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: KNOB_SIZE,
    height: KNOB_SIZE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  knobRing: {
    position: 'absolute',
    width: KNOB_SIZE,
    height: KNOB_SIZE,
    borderRadius: KNOB_SIZE / 2,
    borderWidth: 2,
  },
  knobFace: {
    width: KNOB_SIZE,
    height: KNOB_SIZE,
    borderRadius: KNOB_SIZE / 2,
    backgroundColor: '#1B1C21',
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.22)',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOpacity: 0.45,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 10 },
    elevation: 12,
  },
  knobCore: { width: 34, height: 34, borderRadius: 17 },
});
