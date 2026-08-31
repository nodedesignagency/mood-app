import { useCallback, useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
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
import { MoodArc, type ArcSkin } from '../components/MoodArc';
import { MoodBackdrop, MoodBloom } from '../components/MoodBackdrop';
import { HILL } from '../lib/arc';
import { confirmHaptic, settleHaptic, tickHaptic } from '../lib/haptics';
import { LIGHT_INK, LIGHT_PALETTE, LIGHT_PAPER } from '../theme/moodsLight';
import { SPACING, rounded } from '../theme/tokens';

/** Start in the middle so the arc reads as a scale, not a default answer. */
const INITIAL_MOOD = 2;

const LIGHT_SKIN: ArcSkin = {
  track: LIGHT_PAPER,
  // A wide, soft rim standing in for the drop shadow the SVG blob can't cast.
  rim: 'rgba(28,26,22,0.07)',
  rimWidth: 10,
  guide: 'rgba(28,26,22,0.16)',
  knobFace: LIGHT_PAPER,
  knobBorder: 'rgba(28,26,22,0.10)',
  tintKnob: true,
  faceInk: LIGHT_INK,
  stops: 'faces',
  // The five faces say Awful → Great on their own; word labels would repeat it.
  endCaps: false,
  raised: true,
};

export function MoodCheckInLightScreen() {
  const { width } = useWindowDimensions();
  const insets = useSafeAreaInsets();

  /** The one source of truth: a continuous position along the arc, 0 → 4. */
  const progress = useSharedValue(INITIAL_MOOD);
  /** 1 while a thumb is on the track. */
  const pressed = useSharedValue(0);

  const [index, setIndex] = useState(INITIAL_MOOD);
  const [touched, setTouched] = useState(false);

  const handleCross = useCallback((next: number) => {
    setIndex(next);
    tickHaptic();
  }, []);

  const handleSettle = useCallback((next: number) => {
    setIndex(next);
    setTouched(true);
    settleHaptic();
  }, []);

  const hint = useAnimatedStyle(() => ({ opacity: 1 - pressed.value }));

  return (
    <View style={styles.root}>
      <MoodBackdrop
        progress={progress}
        palette={LIGHT_PALETTE}
        vignette={['rgba(255,255,255,0.5)', 'rgba(255,255,255,0)', 'rgba(255,255,255,0.35)']}
      />

      <View
        style={[
          styles.content,
          { paddingTop: insets.top + 6, paddingBottom: Math.max(insets.bottom, 16) + 6 },
        ]}
      >
        <View style={styles.header}>
          <Text style={styles.date}>{todayLabel()}</Text>
          <Pressable
            style={styles.close}
            accessibilityRole="button"
            accessibilityLabel="Close check-in"
          >
            <Text style={styles.closeGlyph}>✕</Text>
          </Pressable>
        </View>

        {/* The question leads, rather than sitting as an eyebrow above the
            answer. Everything below it is the answer. */}
        <Text style={styles.headline}>How are you{'\n'}feeling today?</Text>

        <View style={styles.stage}>
          <MoodBloom progress={progress} palette={LIGHT_PALETTE} strength={1.5} />
          <Mascot
            progress={progress}
            pressed={pressed}
            palette={LIGHT_PALETTE}
            outline={LIGHT_INK}
            glint
            shadowStrength={0.45}
            scale={1.12}
          />
        </View>

        {/* The label sits directly above the track so it reads as the control's
            current value, not as a separate headline. */}
        <MoodReadout index={index} progress={progress} />

        <View style={styles.controls}>
          <MoodArc
            progress={progress}
            pressed={pressed}
            width={width}
            palette={LIGHT_PALETTE}
            skin={LIGHT_SKIN}
            bend={HILL}
            onCross={handleCross}
            onSettle={handleSettle}
          />
          <Animated.Text style={[styles.hint, hint]}>
            {touched ? 'Slide to adjust' : 'Press and slide'}
          </Animated.Text>
        </View>

        <ContinueButton onPress={confirmHaptic} />
      </View>
    </View>
  );
}

/** The hero word and its one-liner, swapped behind a short fade. */
function MoodReadout({ index, progress }: { index: number; progress: SharedValue<number> }) {
  const swap = useSharedValue(1);

  useEffect(() => {
    swap.value = 0;
    swap.value = withTiming(1, { duration: 240 });
  }, [index, swap]);

  const enter = useAnimatedStyle(() => ({
    opacity: swap.value,
    transform: [{ translateY: interpolate(swap.value, [0, 1], [10, 0]) }],
  }));

  const tint = useAnimatedStyle(() => ({
    color: interpolateColor(progress.value, LIGHT_PALETTE.stops, LIGHT_PALETTE.ink),
  }));

  const mood = LIGHT_PALETTE.moods[index];

  return (
    <View style={styles.readout}>
      <View style={styles.labelSlot}>
        <Animated.Text style={[styles.label, tint, enter]}>{mood.label}</Animated.Text>
      </View>
      <View style={styles.captionSlot}>
        <Animated.Text style={[styles.caption, enter]}>{mood.caption}</Animated.Text>
      </View>
    </View>
  );
}

/**
 * One unambiguous action. The earlier copy — "Log this as Okay" — read as
 * "Log in as…", which is a different verb entirely.
 */
function ContinueButton({ onPress }: { onPress: () => void }) {
  const push = useSharedValue(0);

  const surface = useAnimatedStyle(() => ({
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
      accessibilityLabel="Continue"
    >
      <Animated.View style={[styles.cta, surface]}>
        <Text style={styles.ctaLabel}>Continue</Text>
      </Animated.View>
    </Pressable>
  );
}

/** e.g. "Tue, 1 Sep". */
function todayLabel() {
  return new Date().toLocaleDateString(undefined, {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  });
}

const MUTED = 'rgba(28,26,22,0.5)';

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#F7F5EF' },
  content: { flex: 1, paddingHorizontal: SPACING.gutter },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.lg,
  },
  date: {
    ...rounded('600'),
    fontSize: 12,
    letterSpacing: 1.6,
    textTransform: 'uppercase',
    color: MUTED,
  },
  close: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(28,26,22,0.06)',
  },
  closeGlyph: { fontSize: 13, color: LIGHT_INK, lineHeight: 16 },
  headline: {
    ...rounded('800'),
    fontSize: 30,
    lineHeight: 36,
    letterSpacing: -0.6,
    color: LIGHT_INK,
  },
  stage: { flex: 1, alignItems: 'center', justifyContent: 'center', minHeight: 160 },
  readout: { alignItems: 'center', marginBottom: 16 },
  labelSlot: { height: 52, justifyContent: 'center' },
  label: {
    ...rounded('800'),
    fontSize: 44,
    lineHeight: 52,
    letterSpacing: -1,
    textAlign: 'center',
  },
  captionSlot: { height: 24, justifyContent: 'center' },
  caption: {
    ...rounded('400'),
    fontSize: 15,
    lineHeight: 22,
    color: MUTED,
    textAlign: 'center',
  },
  controls: { alignItems: 'center', marginHorizontal: -SPACING.gutter },
  hint: {
    ...rounded('600'),
    fontSize: 11,
    letterSpacing: 1.8,
    textTransform: 'uppercase',
    color: 'rgba(28,26,22,0.34)',
    marginTop: 12,
  },
  cta: {
    marginTop: SPACING.md,
    height: 58,
    borderRadius: 29,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: LIGHT_INK,
  },
  ctaLabel: {
    ...rounded('700'),
    fontSize: 16,
    letterSpacing: 0.2,
    color: '#FFFFFF',
  },
});
