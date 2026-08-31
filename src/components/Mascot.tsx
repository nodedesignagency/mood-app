import { useEffect } from 'react';
import { StyleSheet, View, type ViewStyle } from 'react-native';
import Animated, {
  Easing,
  interpolate,
  interpolateColor,
  useAnimatedProps,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { G, Path } from 'react-native-svg';

import { DOT_COLORS, MOOD_STOPS } from '../theme/moods';

const AnimatedPath = Animated.createAnimatedComponent(Path);

const BODY_W = 158;
const BODY_H = 140;
const INK = '#17171B';

/** Idle breathing loop, shared by every moving part. */
function useIdle() {
  const idle = useSharedValue(0);
  useEffect(() => {
    idle.value = withRepeat(
      withTiming(1, { duration: 2400, easing: Easing.inOut(Easing.sin) }),
      -1,
      true,
    );
  }, [idle]);
  return idle;
}

type Props = {
  /** Continuous mood position, 0 → 4. */
  progress: SharedValue<number>;
  /** 1 while a thumb is on the track. */
  pressed: SharedValue<number>;
};

/**
 * Placeholder mascot.
 *
 * Deliberately assembled from primitives rather than a static asset: every
 * feature is a function of `progress`, so the face morphs smoothly *between*
 * moods instead of cutting between five drawings. When the real illustrated
 * mascot arrives it can keep this prop contract and reuse the same curves.
 */
export function Mascot({ progress, pressed }: Props) {
  const idle = useIdle();

  const body = useAnimatedStyle(() => {
    const p = progress.value;
    // Low moods squat and sag; high moods stretch and lift.
    const squash = interpolate(p, [0, 2, 4], [0.94, 1, 1.04]);
    const bob = interpolate(idle.value, [0, 1], [4, -6]);
    return {
      backgroundColor: interpolateColor(p, MOOD_STOPS, DOT_COLORS),
      transform: [
        { translateY: bob + interpolate(p, [0, 4], [7, -6]) },
        { rotate: `${interpolate(p, [0, 2, 4], [-4, 0, 4])}deg` },
        { scaleX: 2 - squash },
        { scaleY: squash + pressed.value * 0.03 },
      ],
    };
  });

  const eyes = useAnimatedStyle(() => ({
    transform: [
      { scaleY: interpolate(progress.value, [0, 1, 2, 3, 4], [0.7, 0.86, 1, 0.92, 0.5]) },
    ],
  }));

  const pupils = useAnimatedStyle(() => ({
    transform: [
      { translateY: interpolate(progress.value, [0, 2, 4], [5, 0, -2]) },
      { scale: interpolate(progress.value, [0, 2, 4], [0.86, 1, 1.06]) },
    ],
  }));

  const blush = useAnimatedStyle(() => ({
    opacity: interpolate(progress.value, [0, 2, 3, 4], [0, 0, 0.4, 0.85]),
  }));

  const tint = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
  }));

  const sprout = useAnimatedStyle(() => ({
    transform: [
      {
        rotate: `${
          interpolate(progress.value, [0, 4], [-42, 8]) +
          interpolate(idle.value, [0, 1], [-6, 6])
        }deg`,
      },
    ],
  }));

  // Mouth: a single quadratic whose control point sweeps frown → grin.
  const mouth = useAnimatedProps(() => {
    const p = progress.value;
    const halfW = interpolate(p, [0, 2, 4], [15, 17, 23]);
    const curve = interpolate(p, [0, 1, 2, 3, 4], [-13, -7, 1, 15, 28]);
    return { d: `M ${-halfW} 0 Q 0 ${curve} ${halfW} 0` };
  });

  return (
    <View style={styles.stage}>
      <Shadow progress={progress} idle={idle} style={styles.shadowWide} base={0.14} />
      <Shadow progress={progress} idle={idle} style={styles.shadowCore} base={0.2} />

      <Animated.View style={[styles.body, body]}>
        {/* Sprout on the crown — droops when low, perks up when great. */}
        <Animated.View style={[styles.sprout, sprout]}>
          <Animated.View style={[styles.stalk, tint]} />
          <Animated.View style={[styles.bulb, tint]} />
        </Animated.View>

        <Arm progress={progress} idle={idle} side={-1} />
        <Arm progress={progress} idle={idle} side={1} />

        <Brow progress={progress} side={1} />
        <Brow progress={progress} side={-1} />

        <Animated.View style={[styles.eye, styles.eyeLeft, eyes]}>
          <Animated.View style={[styles.pupil, pupils]} />
        </Animated.View>
        <Animated.View style={[styles.eye, styles.eyeRight, eyes]}>
          <Animated.View style={[styles.pupil, pupils]} />
        </Animated.View>

        <Animated.View style={[styles.blush, styles.blushLeft, blush]} />
        <Animated.View style={[styles.blush, styles.blushRight, blush]} />

        <Svg width={BODY_W} height={56} style={styles.mouth} pointerEvents="none">
          <G x={BODY_W / 2} y={14}>
            <AnimatedPath
              animatedProps={mouth}
              stroke={INK}
              strokeWidth={5}
              strokeLinecap="round"
              fill="none"
            />
          </G>
        </Svg>

        <View style={[styles.leg, styles.legLeft]} />
        <View style={[styles.leg, styles.legRight]} />
      </Animated.View>
    </View>
  );
}

/**
 * A contact shadow. It tightens and lightens as the mascot rises, which is
 * what sells the change in height.
 */
function Shadow({
  progress,
  idle,
  style,
  base,
}: {
  progress: SharedValue<number>;
  idle: SharedValue<number>;
  style: ViewStyle;
  base: number;
}) {
  const animated = useAnimatedStyle(() => {
    const k =
      1 -
      interpolate(progress.value, [0, 4], [0, 0.32]) -
      interpolate(idle.value, [0, 1], [0, 0.08]);
    return { transform: [{ scaleX: k }], opacity: base * k };
  });
  return <Animated.View style={[style, animated]} />;
}

/** One eyebrow. `side` is 1 for the left brow, -1 to mirror it. */
function Brow({ progress, side }: { progress: SharedValue<number>; side: 1 | -1 }) {
  const style = useAnimatedStyle(() => {
    const p = progress.value;
    return {
      transform: [
        { translateY: interpolate(p, [0, 4], [2, -6]) },
        // Inner ends lift for worry, then flatten and drop for delight.
        { rotate: `${side * interpolate(p, [0, 2, 4], [18, 0, -3])}deg` },
      ],
    };
  });
  return (
    <Animated.View
      style={[styles.brow, side === 1 ? styles.browLeft : styles.browRight, style]}
    />
  );
}

/** One arm. `side` is -1 for the left arm, 1 for the right. */
function Arm({
  progress,
  idle,
  side,
}: {
  progress: SharedValue<number>;
  idle: SharedValue<number>;
  side: 1 | -1;
}) {
  const style = useAnimatedStyle(() => {
    const sway = interpolate(idle.value, [0, 1], [-5, 5]);
    return {
      backgroundColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
      transform: [
        { rotate: `${side * (interpolate(progress.value, [0, 2, 4], [12, 0, -48]) + sway)}deg` },
      ],
    };
  });
  return (
    <Animated.View
      style={[styles.arm, side === -1 ? styles.armLeft : styles.armRight, style]}
    />
  );
}

const styles = StyleSheet.create({
  stage: {
    width: BODY_W + 90,
    height: BODY_H + 84,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shadowWide: {
    position: 'absolute',
    bottom: 20,
    width: BODY_W * 0.72,
    height: 17,
    borderRadius: 9,
    backgroundColor: '#000',
  },
  shadowCore: {
    position: 'absolute',
    bottom: 23,
    width: BODY_W * 0.42,
    height: 11,
    borderRadius: 6,
    backgroundColor: '#000',
  },
  body: {
    width: BODY_W,
    height: BODY_H,
    // Uneven radii keep this a hand-drawn blob rather than a perfect ellipse.
    borderTopLeftRadius: 71,
    borderTopRightRadius: 64,
    borderBottomLeftRadius: 56,
    borderBottomRightRadius: 66,
  },
  sprout: {
    position: 'absolute',
    top: -34,
    left: BODY_W / 2 - 3,
    width: 6,
    height: 32,
    alignItems: 'center',
    transformOrigin: '50% 100%',
  },
  stalk: { width: 6, height: 32, borderRadius: 3 },
  bulb: { position: 'absolute', top: -9, width: 17, height: 17, borderRadius: 9 },
  arm: {
    position: 'absolute',
    top: 78,
    width: 11,
    height: 38,
    borderRadius: 6,
    transformOrigin: '50% 0%',
  },
  armLeft: { left: -9 },
  armRight: { right: -9 },
  brow: {
    position: 'absolute',
    top: 32,
    width: 21,
    height: 4,
    borderRadius: 2,
    backgroundColor: INK,
  },
  browLeft: { left: 30 },
  browRight: { right: 30 },
  eye: {
    position: 'absolute',
    top: 46,
    width: 32,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  eyeLeft: { left: 26 },
  eyeRight: { right: 26 },
  pupil: { width: 15, height: 16, borderRadius: 8, backgroundColor: INK },
  blush: {
    position: 'absolute',
    top: 92,
    width: 22,
    height: 12,
    borderRadius: 10,
    backgroundColor: '#FF5C93',
  },
  blushLeft: { left: 14 },
  blushRight: { right: 14 },
  mouth: { position: 'absolute', top: 82, left: 0 },
  leg: {
    position: 'absolute',
    bottom: -14,
    width: 10,
    height: 18,
    borderRadius: 5,
    backgroundColor: INK,
  },
  legLeft: { left: BODY_W / 2 - 24 },
  legRight: { right: BODY_W / 2 - 24 },
});
