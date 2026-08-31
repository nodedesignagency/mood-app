import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

/**
 * Haptics are fire-and-forget: a rejected promise (unsupported device, user
 * setting off) must never surface as an unhandled rejection mid-drag.
 */
const quiet = (p: Promise<void>) => p.catch(() => {});

/** Light tick as the thumb crosses into a new mood. */
export function tickHaptic() {
  if (Platform.OS === 'web') return;
  quiet(Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light));
}

/** Firmer thud when the knob magnetises onto a mood after release. */
export function settleHaptic() {
  if (Platform.OS === 'web') return;
  quiet(Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium));
}

/** Confirmation when the mood is logged. */
export function confirmHaptic() {
  if (Platform.OS === 'web') return;
  quiet(Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success));
}
