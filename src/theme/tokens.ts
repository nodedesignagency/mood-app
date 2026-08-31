import { Platform } from 'react-native';

/** Shared type ramp, spacing and font family names. */

export const FONTS = {
  serif: 'InstrumentSerif_400Regular',
  serifItalic: 'InstrumentSerif_400Regular_Italic',
  sans: 'SpaceGrotesk_400Regular',
  sansMedium: 'SpaceGrotesk_500Medium',
  sansBold: 'SpaceGrotesk_700Bold',
} as const;

export const SPACING = {
  gutter: 24,
  xs: 6,
  sm: 10,
  md: 16,
  lg: 24,
  xl: 36,
} as const;

/** Neutrals that stay put while the mood colours shift underneath them. */
export const NEUTRAL = {
  paper: '#F4F2ED',
  ink: '#0B0B0D',
  dim: 'rgba(255,255,255,0.42)',
  faint: 'rgba(255,255,255,0.34)',
  hairline: 'rgba(255,255,255,0.10)',
} as const;

/** Small uppercase label style used for eyebrows, hints and end-caps. */
export const CAPS = {
  fontFamily: FONTS.sansMedium,
  fontSize: 11,
  letterSpacing: 2.2,
  textTransform: 'uppercase',
} as const;

/**
 * SF Pro Rounded.
 *
 * On iOS this is the real thing, for free: React Native maps the family name
 * `ui-rounded` to `UIFontDescriptorSystemDesignRounded`, so the system draws
 * SF Pro Rounded at whatever `fontWeight` is asked for. Nothing to bundle and
 * no licence question — see RCTFontUtils.mm in react-native.
 *
 * Android and web have no SF, so they fall back to Nunito, the closest freely
 * licensed rounded face. Weight there is carried by the family name, because
 * the fallback is a set of static files rather than one variable font.
 */
const NUNITO: Record<RoundedWeight, string> = {
  '400': 'Nunito_400Regular',
  '600': 'Nunito_600SemiBold',
  '700': 'Nunito_700Bold',
  '800': 'Nunito_800ExtraBold',
};

export type RoundedWeight = '400' | '600' | '700' | '800';

export function rounded(weight: RoundedWeight) {
  return Platform.select({
    ios: { fontFamily: 'ui-rounded', fontWeight: weight },
    default: { fontFamily: NUNITO[weight] },
  }) as { fontFamily: string; fontWeight?: RoundedWeight };
}
