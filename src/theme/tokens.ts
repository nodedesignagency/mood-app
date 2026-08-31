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
