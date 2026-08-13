// src/theme/ThemeProvider.js
import { createContext, useContext, useMemo, useState } from 'react';

// Pull design tokens from your Trulura theme file
import {
  fonts,
  gradients,
  modes,
  palettes,
  radii,
  shadows,
  spacing,
} from './truluraTheme';

// Context that holds full theme tokens (colors, gradients, etc.)
const ThemeContext = createContext(null);

// Context that holds state: current mode + mood
const ModeContext = createContext(null);

export function ThemeProvider({ children }) {
  // Which major area is active: Home / Glow / Spark / Vent / Explore
  const [modeKey, setModeKey] = useState('Home');

  // Emotional mood used by Glow / Vent / future features
  const [mood, setMood] = useState('calm'); // calm | reflective | spicy

  const mode = modes[modeKey] || modes.Home;

  // Everything design-related your components can read
  const themeValue = useMemo(
    () => ({
      palettes,
      gradients,
      spacing,
      radii,
      fonts,
      shadows,
      mode,
      modeKey,
      mood,
    }),
    [mode, modeKey, mood],
  );

  // State-only context (what mode/mood we’re in + setters)
  const modeValue = useMemo(
    () => ({
      modeKey,
      setModeKey,
      mood,
      setMood,
    }),
    [modeKey, mood],
  );

  return (
    <ThemeContext.Provider value={themeValue}>
      <ModeContext.Provider value={modeValue}>{children}</ModeContext.Provider>
    </ThemeContext.Provider>
  );
}

/* ---------------- base hooks: new API ---------------- */

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used inside <ThemeProvider>');
  return ctx;
}

export function useMode() {
  const ctx = useContext(ModeContext);
  if (!ctx) throw new Error('useMode must be used inside <ThemeProvider>');
  return ctx;
}

/* ---------------- bridge hook: old API (useTruTheme) ---------------- */

/**
 * useTruTheme keeps older screens working.
 *
 * It returns an object with:
 * - bg, text, accents  (what your screens already use)
 * - theme: same object again (for code that does `const { theme } = useTruTheme()`)
 * - mood, setMood
 * - plus raw tokens (palettes, gradients, etc.) if you want them.
 */
export function useTruTheme() {
  const base = useTheme(); // { palettes, gradients, spacing, radii, fonts, shadows, mode, modeKey, mood }
  const { mood, setMood } = useMode();

  // Simple derived palettes for backgrounds / text
  const bg = {
    app: '#020415',
    card: palettes.card || '#121325',
    panel: palettes.card || '#121325',
  };

  const text = {
    primary: palettes.white || '#ffffff',
    secondary: palettes.dim || 'rgba(255,255,255,0.85)',
    mute: palettes.mute || 'rgba(255,255,255,0.65)',
    subtle: palettes.subtle || 'rgba(255,255,255,0.4)',
  };

  const accents = {
    home: modes.Home?.accent ?? '#5ce2c0',
    glow: modes.Glow?.accent ?? palettes.glow,
    spark: modes.Spark?.accent ?? palettes.spark,
    vent: modes.Vent?.accent ?? palettes.vent,
    explore: modes.Explore?.accent ?? palettes.explore,
  };

  const publicTheme = {
    palettes,
    gradients,
    spacing,
    radii,
    fonts,
    shadows,
    mode: base.mode,
    modeKey: base.modeKey,
    mood,
    bg,
    text,
    accents,
  };

  // Return object that satisfies BOTH patterns:
  // - `const theme = useTruTheme(); theme.bg...`
  // - `const { theme, mood } = useTruTheme();`
  return {
    ...publicTheme,
    theme: publicTheme,
    mood,
    setMood,
  };
}

// Default export for App.js
export default ThemeProvider;
