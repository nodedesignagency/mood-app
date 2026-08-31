import { useCallback, useEffect, useState } from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, {
  interpolate,
  interpolateColor,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';

import { Mascot } from '../components/Mascot';
import { MoodArc } from '../components/MoodArc';
import { MoodBackdrop, MoodBloom } from '../components/MoodBackdrop';
import { confirmHaptic, settleHaptic, tickHaptic } from '../lib/haptics';
import { DOT_COLORS, INK_COLORS, MOODS, MOOD_STOPS } from '../theme/moods';
import { CAPS, FONTS, NEUTRAL, SPACING } from '../theme/tokens';

/** Start in the middle so the arc reads as a scale, not a default answer. */
const INITIAL_MOOD = 2;

export function MoodCheckInScreen() {
  const { width } = useWindowDimensions();
  const insets = useSafeAreaInsets();

  /** The one source of truth: a continuous position along the arc, 0 → 4. */
  const progress = useSharedValue(INITIAL_MOOD);
  /** 1 while a thumb is on the track. */
  const pressed = useSharedValue(0);

  const [index, setIndex] = useState(INITIAL_MOOD);
  const [logged, setLogged] = useState(false);

  const handleCross = useCallback((next: number) => {
    setIndex(next);
    tickHaptic();
  }, []);

  const handleSettle = useCallback((next: number) => {
    setIndex(next);
    setLogged(false);
    settleHaptic();
  }, []);

  const handleLog = useCallback(() => {
    confirmHaptic();
    setLogged(true);
  }, []);

  const hint = useAnimatedStyle(() => ({
    // The prompt has done its job once a thumb is down.
    opacity: 1 - pressed.value * 0.75,
  }));

  const streakDot = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
  }));

  const mood = MOODS[index];

  return (
    <View style={styles.root}>
      <MoodBackdrop progress={progress} />

      <View
        style={[
          styles.content,
          { paddingTop: insets.top + 8, paddingBottom: Math.max(insets.bottom, 16) + 8 },
        ]}
      >
        <View style={styles.header}>
          <Text style={styles.headerLabel}>{todayLabel()}</Text>
          <View style={styles.streak}>
            <Animated.View style={[styles.streakDot, streakDot]} />
            <Text style={styles.headerLabel}>7 day streak</Text>
          </View>
        </View>

        <View style={styles.stage}>
          <MoodBloom progress={progress} />
          <Mascot progress={progress} pressed={pressed} />
        </View>

        <View style={styles.hero}>
          <Text style={styles.eyebrow}>How are you feeling?</Text>
          <HeroLabel index={index} progress={progress} />
        </View>

        <View style={styles.controls}>
          <MoodArc
            progress={progress}
            pressed={pressed}
            width={width}
            onCross={handleCross}
            onSettle={handleSettle}
          />
          <Animated.Text style={[styles.hint, hint]}>Press &amp; slide</Animated.Text>
        </View>

        <LogButton progress={progress} logged={logged} onPress={handleLog} label={mood.label} />
      </View>
    </View>
  );
}

/**
 * The hero word and its one-liner.
 *
 * Both are re-keyed off React state rather than the shared value, because text
 * content cannot live on the UI thread. The swap is masked by a short fade so
 * the change never reads as a pop.
 */
function HeroLabel({ index, progress }: { index: number; progress: SharedValue<number> }) {
  const swap = useSharedValue(1);

  useEffect(() => {
    swap.value = 0;
    swap.value = withTiming(1, { duration: 260 });
  }, [index, swap]);

  const enter = useAnimatedStyle(() => ({
    opacity: swap.value,
    transform: [{ translateY: interpolate(swap.value, [0, 1], [12, 0]) }],
  }));

  const tint = useAnimatedStyle(() => ({
    color: interpolateColor(progress.value, MOOD_STOPS, INK_COLORS),
  }));

  const mood = MOODS[index];

  return (
    <>
      <View style={styles.labelSlot}>
        <Animated.Text style={[styles.label, tint, enter]}>{mood.label}</Animated.Text>
      </View>
      <View style={styles.captionSlot}>
        <Animated.Text style={[styles.caption, enter]}>{mood.caption}</Animated.Text>
      </View>
    </>
  );
}

function LogButton({
  progress,
  logged,
  onPress,
  label,
}: {
  progress: SharedValue<number>;
  logged: boolean;
  onPress: () => void;
  label: string;
}) {
  const push = useSharedValue(0);

  const surface = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, MOOD_STOPS, DOT_COLORS),
    transform: [{ scale: 1 - push.value * 0.03 }],
  }));

  return (
    <Pressable
      onPressIn={() => {
        push.value = withTiming(1, { duration: 90 });
      }}
      onPressOut={() => {
        push.value = withSpring(0, { damping: 14, stiffness: 220 });
      }}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={`Log today as ${label}`}
    >
      <Animated.View style={[styles.cta, surface]}>
        <Text style={styles.ctaLabel}>
          {logged ? `Logged as ${label}` : `Log this as ${label}`}
        </Text>
      </Animated.View>
    </Pressable>
  );
}

/** e.g. "Sun 31 Aug". */
function todayLabel() {
  return new Date().toLocaleDateString(undefined, {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  });
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#131418' },
  content: { flex: 1, paddingHorizontal: SPACING.gutter },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerLabel: { ...CAPS, color: NEUTRAL.dim },
  streak: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  streakDot: { width: 7, height: 7, borderRadius: 4 },
  stage: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 180,
  },
  hero: { alignItems: 'center', marginBottom: 30 },
  eyebrow: { ...CAPS, color: NEUTRAL.dim, marginBottom: SPACING.sm },
  labelSlot: { height: 66, justifyContent: 'center' },
  label: {
    fontFamily: FONTS.serif,
    fontSize: 60,
    lineHeight: 66,
    textAlign: 'center',
  },
  captionSlot: { height: 28, justifyContent: 'center' },
  caption: {
    fontFamily: FONTS.serifItalic,
    fontSize: 19,
    lineHeight: 26,
    color: NEUTRAL.dim,
    textAlign: 'center',
  },
  controls: { alignItems: 'center', marginHorizontal: -SPACING.gutter },
  hint: { ...CAPS, color: NEUTRAL.faint, marginTop: 14 },
  cta: {
    marginTop: SPACING.lg,
    height: 58,
    borderRadius: 29,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ctaLabel: {
    fontFamily: FONTS.sansMedium,
    fontSize: 15,
    letterSpacing: 0.2,
    color: NEUTRAL.ink,
  },
});
