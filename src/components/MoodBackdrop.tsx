import { StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  clamp,
  interpolate,
  interpolateColor,
  useAnimatedStyle,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Defs, RadialGradient, Rect, Stop } from 'react-native-svg';

import { BG_COLORS, GLOW_COLORS, MOOD_STOPS } from '../theme/moods';

type Props = { progress: SharedValue<number> };

/**
 * Full-screen background that re-tints as the thumb travels.
 *
 * Two layers: a deep base colour, and a static wash that darkens top and
 * bottom so the arc reads as sitting in shadow.
 */
export function MoodBackdrop({ progress }: Props) {
  const base = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, MOOD_STOPS, BG_COLORS),
  }));

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <Animated.View style={[StyleSheet.absoluteFill, base]} />
      <LinearGradient
        colors={['rgba(0,0,0,0.32)', 'rgba(0,0,0,0)', 'rgba(0,0,0,0.5)']}
        locations={[0, 0.42, 1]}
        style={StyleSheet.absoluteFill}
      />
    </View>
  );
}

const BLOOM = 560;
/** offset → opacity along the glow's falloff. */
const FALLOFF: [string, number][] = [
  ['0', 0.34],
  ['0.35', 0.17],
  ['0.62', 0.06],
  ['1', 0],
];

/**
 * Soft coloured halo behind the mascot.
 *
 * One static radial gradient per mood, stacked and cross-faded by opacity.
 *
 * The obvious implementation — a single gradient whose stop colours animate —
 * does not work on native: `Stop` lives inside `<Defs>` and is not a host
 * view, so Reanimated has nothing to attach to ("Cannot find host instance").
 * It only appears to work on web, where react-native-svg emits real DOM nodes.
 * Stacked concentric circles were the other option, but they band visibly at
 * these opacities.
 */
export function MoodBloom({ progress }: Props) {
  const swell = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(progress.value, [0, 4], [0.9, 1.1]) }],
  }));

  return (
    <Animated.View style={[styles.bloom, swell]} pointerEvents="none">
      {GLOW_COLORS.map((color, i) => (
        <GlowLayer key={color} progress={progress} index={i} color={color} />
      ))}
    </Animated.View>
  );
}

function GlowLayer({
  progress,
  index,
  color,
}: Props & { index: number; color: string }) {
  const style = useAnimatedStyle(() => ({
    // A tent: full strength at its own mood, zero once `progress` reaches
    // either neighbour. Only the two adjacent layers are ever non-zero, so the
    // glow is a clean blend of the pair being travelled between.
    //
    // Ramping every lower layer up to 1 instead (the intuitive "stack them"
    // approach) does not work here: these gradients peak at 34% alpha, so
    // every layer underneath still shows through and the halo turns into the
    // sum of all the moods behind it.
    opacity: clamp(1 - Math.abs(progress.value - index), 0, 1),
  }));

  const id = `bloom-${index}`;

  return (
    <Animated.View style={[StyleSheet.absoluteFill, style]}>
      <Svg width={BLOOM} height={BLOOM}>
        <Defs>
          <RadialGradient id={id} cx="50%" cy="50%" r="50%">
            {FALLOFF.map(([offset, opacity]) => (
              <Stop key={offset} offset={offset} stopColor={color} stopOpacity={opacity} />
            ))}
          </RadialGradient>
        </Defs>
        <Rect width={BLOOM} height={BLOOM} fill={`url(#${id})`} />
      </Svg>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  bloom: {
    position: 'absolute',
    width: BLOOM,
    height: BLOOM,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
