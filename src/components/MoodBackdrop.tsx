import { StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  interpolate,
  interpolateColor,
  useAnimatedProps,
  useAnimatedStyle,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Defs, RadialGradient, Rect, Stop } from 'react-native-svg';

import { BG_COLORS, GLOW_COLORS, MOOD_STOPS } from '../theme/moods';

const AnimatedStop = Animated.createAnimatedComponent(Stop);

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
 * A real SVG radial gradient rather than stacked circles — concentric views
 * band visibly at these opacities. Only the stop *colours* are animated; the
 * geometry is static, so this costs nothing per frame.
 */
export function MoodBloom({ progress }: Props) {
  const swell = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(progress.value, [0, 4], [0.9, 1.1]) }],
  }));

  return (
    <Animated.View style={[styles.bloom, swell]} pointerEvents="none">
      <Svg width={BLOOM} height={BLOOM}>
        <Defs>
          <RadialGradient id="bloom" cx="50%" cy="50%" r="50%">
            {FALLOFF.map(([offset, opacity]) => (
              <GlowStop key={offset} progress={progress} offset={offset} opacity={opacity} />
            ))}
          </RadialGradient>
        </Defs>
        <Rect width={BLOOM} height={BLOOM} fill="url(#bloom)" />
      </Svg>
    </Animated.View>
  );
}

function GlowStop({
  progress,
  offset,
  opacity,
}: Props & { offset: string; opacity: number }) {
  const animatedProps = useAnimatedProps(() => ({
    stopColor: interpolateColor(progress.value, MOOD_STOPS, GLOW_COLORS),
  }));
  return <AnimatedStop offset={offset} stopOpacity={opacity} animatedProps={animatedProps} />;
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
