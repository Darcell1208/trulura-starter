// src/theme/truluraTheme.js

const baseColors = {
  black: '#050509',
  white: '#FFFFFF',
  softWhite: 'rgba(255,255,255,0.9)',
  slate: '#111827',
  slateSoft: '#1F2937',
  slateSofter: '#111827',
  danger: '#F97373',
  success: '#22C55E',
  warning: '#FBBF24',
  neutral: '#9CA3AF',
};

export const moodColors = {
  default: {
    background: '#050814',
    card: '#101624',
    accent: '#7C3AED',
    accentSoft: 'rgba(124,58,237,0.18)',
    accentStrong: '#A855F7',
  },
  spark: {
    background: '#080616',
    card: '#151126',
    accent: '#FB7185',
    accentSoft: 'rgba(251,113,133,0.22)',
    accentStrong: '#F97373',
  },
  glow: {
    background: '#020617',
    card: '#0B1020',
    accent: '#22C55E',
    accentSoft: 'rgba(34,197,94,0.20)',
    accentStrong: '#4ADE80',
  },
  vent: {
    background: '#020617',
    card: '#111827',
    accent: '#38BDF8',
    accentSoft: 'rgba(56,189,248,0.20)',
    accentStrong: '#0EA5E9',
  },
};

export const palettes = {
  white: baseColors.white,
  dim: 'rgba(255,255,255,0.85)',
  mute: 'rgba(255,255,255,0.65)',
  subtle: 'rgba(255,255,255,0.4)',
  card: moodColors.default.card,
  glow: moodColors.glow.accent,
  spark: moodColors.spark.accent,
  vent: moodColors.vent.accent,
  explore: '#8B5CF6',
};

export const spacing = {
  xs: 6,
  sm: 10,
  md: 16,
  lg: 22,
  xl: 28,
};

export const radii = {
  sm: 10,
  md: 16,
  lg: 22,
  xl: 30,
};

export const shadows = {
  softGlow: {
    shadowColor: '#7C3AED',
    shadowOpacity: 0.35,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 8 },
    elevation: 12,
  },
};

export const gradients = {
  sunrise: ['#6B73FF', '#FF8E53'],
  aurora: ['#0EA5E9', '#6366F1', '#A855F7'],
  calm: ['#0ea5e9', '#22c55e'],
};

export const fonts = {
  primary: 'System',
  secondary: 'System',
};

export const modes = {
  Home: { accent: '#5ce2c0' },
  Glow: { accent: moodColors.glow.accent },
  Spark: { accent: moodColors.spark.accent },
  Vent: { accent: moodColors.vent.accent },
  Explore: { accent: '#8B5CF6' },
};

export const truluraTheme = {
  colors: {
    ...baseColors,
    ...moodColors.default,
  },
  radius: radii,
  spacing,
  typography: {
    title: 24,
    subtitle: 18,
    body: 14,
    caption: 12,
  },
  shadows,
};

/**
 * Helper to get theme colors for a given mood:
 * mood = "spark" | "glow" | "vent" | "default"
 */
export const getMoodPalette = (mood = 'default') => {
  const palette = moodColors[mood] || moodColors.default;
  return {
    ...truluraTheme,
    colors: {
      ...truluraTheme.colors,
      ...palette,
    },
  };
};
