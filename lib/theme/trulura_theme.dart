
import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

/// TruLuraTheme
///
/// This file exists to support the newer “TruLuraTheme.*” API you shared
/// (used by some mockups/snippets), while **reusing** the existing, already
///-adopted token system in `lib/theme.dart`.
///
/// Why: the repo already contains a more complete palette + glass system
/// (mode-aware, Soft Mode aware, etc.). Duplicating those tokens would cause
/// visual drift. So this class is an adapter.
///
/// Note: Flutter 2025 deprecates `Color.withOpacity()`. This adapter uses
/// `withValues(alpha: ...)` everywhere.
class TruLuraTheme {
  // Core palette (cinematic indigo → violet → magenta)
  static const Color ink = TruLuraTokens.ink;
  static const Color deep = TruLuraTokens.deepIndigo;
  static const Color indigo = TruLuraTokens.nebula;

  // These map to existing “aura” tokens.
  static const Color violet = TruLuraTokens.auraViolet;
  static const Color magenta = TruLuraTokens.auraPink;
  static const Color auraCyan = TruLuraTokens.auraCyan;
  static const Color auraPurple = TruLuraTokens.auraViolet;
  static const Color auraPink = TruLuraTokens.auraPink;

  // Glass defaults (kept subtle; the full glass spec is implemented by
  // `TruLuraGlassCard`.)
  static const Color glassStroke = Color(0x33FFFFFF);
  static const Color glassFill = Color(0x14000000);

  static const BorderRadius r16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius r20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius r24 = BorderRadius.all(Radius.circular(24));

  static TextStyle get h1 => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: Colors.white,
      );

  static TextStyle get h2 => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get body => TextStyle(
        fontSize: 13,
        height: 1.25,
        color: Colors.white.withValues(alpha: 0.86),
      );

  static TextStyle get subtle => TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.62),
      );

  /// Cinematic background gradient.
  ///
  /// The repo’s canonical background is actually layered (see
  /// `TruLuraLayeredBackground`). This gradient is provided as a compatible
  /// underlay for snippet usage.
  static LinearGradient get cinematicBg => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF101433),
          Color(0xFF201C4A),
          Color(0xFF3A1F5E),
          Color(0xFF120A1F),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      );

  static LinearGradient auraGlowGradient({Color? a, Color? b}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (a ?? auraPurple).withValues(alpha: 0.95),
          (b ?? auraPink).withValues(alpha: 0.95),
        ],
      );

  // ---------------------------------------------------------------------------
  // Compatibility aliases
  // ---------------------------------------------------------------------------

  /// Alias used by some early snippets.
  static LinearGradient get cosmicGradient => cinematicBg;

  /// Alias used by some early snippets.
  static LinearGradient get primaryGlow => auraGlowGradient(a: auraCyan, b: auraPink);

  /// Alias used by some early snippets.
  static const Color cyan = auraCyan;

  static BoxShadow softGlow(Color c, {double blur = 26, double spread = -8}) => BoxShadow(
        color: c.withValues(alpha: 0.35),
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, 12),
      );

  static BoxShadow softShadow() => BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 22,
        spreadRadius: -10,
        offset: const Offset(0, 16),
      );

  /// A minimal Material3 dark ThemeData.
  ///
  /// The app currently uses `theme.dart` as the source of truth. Keep using
  /// that in `main.dart` unless you explicitly want to switch.
  static ThemeData get material => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        fontFamily: null,
        colorScheme: const ColorScheme.dark(
          primary: auraPurple,
          secondary: auraPink,
          surface: deep,
        ),
      );
}

/// Back-compat shim for snippets that reference `TruluraTheme.*`.
///
/// The canonical theme adapter is [TruLuraTheme]. Keep using that in app code;
/// this shim exists so feature snippets compile without refactors.
class TruluraTheme {
  static LinearGradient get cosmicGradient => TruLuraTheme.cosmicGradient;
  static LinearGradient get primaryGlow => TruLuraTheme.primaryGlow;
  static const Color cyan = TruLuraTheme.cyan;
}
