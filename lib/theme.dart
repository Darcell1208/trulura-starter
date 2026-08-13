import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trulura/models/user.dart';

/// Central place to swap brand assets (logo, app icon, wordmark) without
/// hunting through the codebase.
class TruLuraAssets {
  /// Current in-repo logo (fallback). Replace this with the final uploaded
  /// TruLura logo/wordmark when ready.
  static const String logoSquare =
      'assets/images/ChatGPT_Image_Feb_26_2026_10_51_27_PM.png';

  /// Recommended path for your final launcher icon.
  ///
  /// Upload the exact concept icon PNG/JPG into `assets/icons/` and then update
  /// `pubspec.yaml > flutter_launcher_icons.image_path` to point here.
  static const String launcherIconSuggested =
      'assets/icons/trulura_launcher_icon.png';

  /// Optional: a wide wordmark asset (if you upload one).
  static const String wordmarkSuggested = 'assets/icons/trulura_wordmark.png';

  // Optional: if you upload the exact concept tab icons, drop them here and
  // swap the bottom nav to use them.
  static const String navAuraSuggested = 'assets/icons/nav_aura.png';
  static const String navSyncSuggested = 'assets/icons/nav_sync.png';
  static const String navExploreSuggested = 'assets/icons/nav_explore.png';
  static const String navChatSuggested = 'assets/icons/nav_chat.png';
  static const String navProfileSuggested = 'assets/icons/nav_profile.png';
}

/// Centralized, cinematic design tokens (indigo → violet → magenta).
///
/// These are the “source of truth” values you shared. We keep existing
/// [TruLuraBrandColors] for backwards compatibility across the app, but
/// new/retouched surfaces should prefer [TruLuraTokens].
class TruLuraTokens {
  // Core hues (cinematic indigo → violet → magenta)
  static const Color ink = Color(0xFF070A1A);
  static const Color deepIndigo = Color(0xFF0C1030);
  static const Color nebula = Color(0xFF1A1D4E);
  static const Color auraViolet = Color(0xFF6C4BFF);
  static const Color auraPink = Color(0xFFFF4FD8);
  static const Color auraCyan = Color(0xFF37D5FF);

  // Text
  static const Color textPrimary = Color(0xFFF3F4FF);
  static const Color textSecondary = Color(0xFFB8BBE6);
  static const Color textMuted = Color(0xFF8A8EC9);

  // Surfaces
  static const double glassBlur = 18;
  static const double glassOpacity = 0.10;
  // Hairline stroke on glass surfaces (mocks use very subtle borders).
  static const double strokeOpacity = 0.16;

  // Radius
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;

  // Spacing
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  static List<BoxShadow> softGlow(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: 0.22),
          blurRadius: 26,
          spreadRadius: 2,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: c.withValues(alpha: 0.12),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 18),
        ),
      ];

  static LinearGradient auraGradient({double opacity = 1}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          auraViolet.withValues(alpha: opacity),
          auraPink.withValues(alpha: opacity),
        ],
      );

  static LinearGradient backgroundGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          deepIndigo,
          nebula,
          Color(0xFF0B0E28),
        ],
      );

  static LinearGradient identityGradient(TruIdentityMode mode,
      {double opacity = 1}) {
    switch (mode) {
      case TruIdentityMode.social:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              auraCyan.withValues(alpha: opacity),
              auraViolet.withValues(alpha: opacity)
            ]);
      case TruIdentityMode.friendship:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6AF7C8).withValues(alpha: opacity),
              auraCyan.withValues(alpha: opacity)
            ]);
      case TruIdentityMode.dating:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              auraPink.withValues(alpha: opacity),
              auraViolet.withValues(alpha: opacity)
            ]);
      case TruIdentityMode.creator:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFC34F).withValues(alpha: opacity),
              auraPink.withValues(alpha: opacity)
            ]);
      case TruIdentityMode.luxe:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFBFA6FF).withValues(alpha: opacity),
              const Color(0xFF6BFFF5).withValues(alpha: opacity)
            ]);
      case TruIdentityMode.vent:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7C8DFF).withValues(alpha: opacity),
              const Color(0xFF2AE6B2).withValues(alpha: opacity)
            ]);
    }
  }
}

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // TruLura spacing tokens (requested)
  static const double sectionV = 20.0;
  static const double chipGap = 12.0;
  static const double blockV = 24.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  /// TruLura default card radius (rounded, soft, modern)
  static const double card = 24.0;

  static const double chip = 24.0;
  static const double button = 30.0;
}

// =============================================================================
// TRULURA VISUAL TOKENS
// =============================================================================

class TruLuraBrandColors {
  // =============================================================================
  // LOCKED: TRULURA COSMIC SYSTEM (FINAL)
  // =============================================================================
  /// Core cosmic tokens (Trulura Main)
  // Locked background base for “Subtle Intimate Cosmic”
  // Spec: linear-gradient(180deg, #060914 0%, #0A0F22 100%)
  static const Color cosmicBase = Color(0xFF060914);
  static const Color cosmicNavyLocked = Color(0xFF0B1023);
  static const Color cosmicBlue = Color(0xFF1436A6);
  static const Color cosmicIndigo = Color(0xFF2B1C6B);
  static const Color cosmicPurple = Color(0xFF6A2BFF);

  /// Sync-only rose accent (must never dominate globally)
  static const Color syncRose = Color(0xFFFF5FA8);

  /// Text
  static const Color textPrimaryLocked = Color(0xFFF2F4FF);
  static const Color textSecondaryLocked = Color(0xB8F2F4FF); // ~0.72
  static const Color textMutedLocked = Color(0x85F2F4FF); // ~0.52

  /// Glass surface
  static const Color glassFill = Color(0x8C101634); // rgba(16,22,52,0.55)
  static const Color glassFillStrong = Color(0xB8161634); // rgba(16,22,52,0.72)
  static const Color glassBorder = Color(0x2978A0FF); // rgba(120,160,255,0.16)
  static const Color glassBorderStrong =
      Color(0x38A0BEFF); // rgba(160,190,255,0.22)

  /// Controlled glows
  static const Color glowBlue = Color(0x73468CFF); // rgba(70,140,255,0.45)
  static const Color glowPurple = Color(0x599650FF); // rgba(150,80,255,0.35)
  static const Color glowRoseSyncOnly =
      Color(0x3DFF69B4); // rgba(255,105,180,0.24)

  /// TruLura primary background token (requested): #0F1029
  static const Color midnightA = Color(0xFF0F1029);
  static const Color midnightB = Color(0xFF0E1A3A);
  static const Color midnightC = Color(0xFF101B3F);

  /// Cosmic Aura base (Core): deep navy -> cobalt -> violet haze.
  static const Color cosmicNavy = cosmicBase;
  static const Color cosmicDeep = cosmicNavyLocked;
  static const Color cosmicCobalt = cosmicBlue;
  static const Color cosmicVioletHaze = cosmicIndigo;

  /// Nebula tints (subtle, premium)
  static const Color nebulaViolet = Color(0xFF5B2BFF);
  // Keep magenta available for legacy styling, but avoid using it as a wash.
  static const Color nebulaMagenta = Color(0xFFFF2DAA);
  static const Color nebulaIndigo = Color(0xFF1A5CFF);

  /// Neon aura accents
  /// Primary glow token (brand): #7C4DFF
  ///
  /// Note: some earlier iterations of the app used a slightly warmer purple.
  /// We keep that as [neonPurpleLegacy] for backwards-compatible fine-tuning.
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color neonBlue = Color(0xFF3A7BFF);

  /// Secondary glow token (brand): #FF3DFF
  static const Color sparkMagenta = Color(0xFFFF3DFF);

  /// Previous iteration values kept for screens/widgets that were tuned around them.
  static const Color neonPurpleLegacy = Color(0xFF8F5CFF);
  static const Color sparkMagentaLegacy = Color(0xFFFF6BD6);
  static const Color glowGold = Color(0xFFFFD166);

  static const Color deepBlue = Color(0xFF2563EB);
  static const Color electricBlue = Color(0xFF3A7BFF);

  /// Text tokens (Core)
  static const Color textSoftWhite = textPrimaryLocked;
  static const Color textLavenderGray = Color(0xFFB8B4D8);

  /// Edge glow/border tint (faint, not harsh)
  static const Color edgeBlue = Color(0xFF3A7BFF);
  static const Color edgePurple = Color(0xFF8F5CFF);
}

class TruLuraGradients {
  /// Card surface token (requested): LinearGradient([#1A1B3F, #262A5B])
  static const LinearGradient cardSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1B3F), Color(0xFF262A5B)],
  );

  /// TruDating “Full Sync Mode” background: deep plum + midnight + soft rose.
  static const LinearGradient truDatingNebula = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF230B2C), Color(0xFF0B1230), Color(0xFF3A0D2B)],
  );

  /// LOCKED: Base background for all screens is a layered atmosphere.
  ///
  /// We still keep a subtle vertical gradient as an underlay (Layer 1).
  static const LinearGradient cosmicBaseVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    // Updated to match TruLuraTokens (cinematic indigo base).
    colors: [TruLuraTokens.ink, TruLuraTokens.deepIndigo],
  );
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFF14B8A6)],
  );

  /// Deep-blue + violet wash used to keep dark mode emotionally alive.
  static const LinearGradient midnightAura = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      TruLuraBrandColors.midnightA,
      TruLuraBrandColors.midnightB,
      TruLuraBrandColors.midnightC
    ],
  );

  /// Core cosmic background base (Core): deep navy -> cobalt -> violet haze.
  static const LinearGradient cosmicAuraBase = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      TruLuraBrandColors.cosmicNavy,
      TruLuraBrandColors.cosmicDeep,
      TruLuraBrandColors.cosmicCobalt,
      TruLuraBrandColors.cosmicVioletHaze,
    ],
    stops: [0.0, 0.42, 0.74, 1.0],
  );

  /// Richer primary button gradient (less flat, more “social app” energy).
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    // Brighter, cleaner “aura” CTA: violet → pink → cyan.
    colors: [
      TruLuraTokens.auraViolet,
      TruLuraTokens.auraPink,
      TruLuraTokens.auraCyan
    ],
  );

  static LinearGradient auraForTone(TruLuraModeTone tone, ColorScheme cs) {
    final (a, b) = tone.resolve(cs);
    return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]);
  }

  static LinearGradient softSurface(Brightness brightness) {
    if (brightness == Brightness.dark) {
      // Slightly stronger, more colorful dark wash (avoid flat black).
      return cosmicAuraBase;
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFBFF), Color(0xFFFAF5FF), Color(0xFFF0FDFA)],
    );
  }

  static LinearGradient pillSelected(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B5CF6), Color(0xFFF472B6)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    );
  }
}

class TruLuraEffects {
  static List<BoxShadow> softGlow(Color color, {double intensity = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.18 * intensity),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.10 * intensity),
          blurRadius: 38,
          offset: const Offset(0, 22),
        ),
      ];

  static List<BoxShadow> multiAuraGlow(Color a, Color b,
          {double intensity = 1}) =>
      [
        BoxShadow(
          color: a.withValues(alpha: 0.20 * intensity),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: b.withValues(alpha: 0.18 * intensity),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: a.withValues(alpha: 0.10 * intensity),
          blurRadius: 44,
          offset: const Offset(0, 28),
        ),
      ];

  static List<BoxShadow> premiumCardDepth(Color shadow,
          {double intensity = 1}) =>
      [
        BoxShadow(
          color: shadow.withValues(alpha: 0.22 * intensity),
          blurRadius: 26,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: shadow.withValues(alpha: 0.12 * intensity),
          blurRadius: 60,
          offset: const Offset(0, 30),
        ),
      ];
}

/// Shared surface styling tokens used across glass panels, docks, and sheets.
///
/// Keep these centralized so the "cinematic nebula glass" look stays consistent.
class TruLuraSurfaces {
  // LOCKED tokens
  static const double glassBlurStrong = 16;
  static const double glassBlurSoft = 8;

  /// Dark glass (cinematic) container alpha.
  static const double glassDarkA = 0.52;
  static const double glassDarkB = 0.34;

  /// Light glass container alpha.
  static const double glassLightA = 0.82;
  static const double glassLightB = 0.66;

  static const double hairline = 1;
}

/// Mode tone mapping used across pills, avatars, and mode-specific accents.
///
/// Brand language:
/// - Aura: cool blue-violet, calmer energy
/// - Sync: warmer magenta undertone, stronger halo
/// - Explore: balanced, neutral cosmic tone
enum TruLuraModeTone { aura, sync, explore, messages, notifications, profile }

extension TruLuraModeToneX on TruLuraModeTone {
  (Color, Color) resolve(ColorScheme cs) {
    switch (this) {
      case TruLuraModeTone.sync:
        // LOCKED: Sync is purple dominant with subtle rose accents.
        return (TruLuraBrandColors.cosmicPurple, TruLuraBrandColors.syncRose);
      case TruLuraModeTone.explore:
        return (
          TruLuraBrandColors.nebulaIndigo,
          TruLuraBrandColors.nebulaViolet
        );
      case TruLuraModeTone.messages:
        return (TruLuraTokens.auraCyan, TruLuraBrandColors.neonPurple);
      case TruLuraModeTone.notifications:
        return (TruLuraBrandColors.glowGold, TruLuraBrandColors.neonPurple);
      case TruLuraModeTone.profile:
        return (TruLuraTokens.auraPink, TruLuraTokens.auraCyan);
      case TruLuraModeTone.aura:
        return (TruLuraBrandColors.neonBlue, TruLuraBrandColors.neonPurple);
    }
  }
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

class LightModeColors {
  static const lightPrimary = Color(0xFF7C3AED);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFF3E8FF);
  static const lightOnPrimaryContainer = Color(0xFF4C1D95);

  static const lightSecondary = Color(0xFFEC4899);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  static const lightSecondaryContainer = Color(0xFFFCE7F3);
  static const lightOnSecondaryContainer = Color(0xFF9D174D);

  static const lightTertiary = Color(0xFF14B8A6);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  static const lightTertiaryContainer = Color(0xFFCCFBF1);
  static const lightOnTertiaryContainer = Color(0xFF115E59);

  static const lightError = Color(0xFFEF4444);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFEE2E2);
  static const lightOnErrorContainer = Color(0xFF991B1B);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1F2937);
  static const lightBackground = Color(0xFFFAF5FF);
  static const lightSurfaceVariant = Color(0xFFF9FAFB);
  static const lightOnSurfaceVariant = Color(0xFF6B7280);

  static const lightSurfaceTint = Color(0xFF7C3AED);

  static const lightOutline = Color(0xFFD1D5DB);
  static const lightShadow = Color(0xFF000000);
  static const lightInversePrimary = Color(0xFFA78BFA);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFFA78BFA);
  static const darkOnPrimary = Color(0xFF4C1D95);
  static const darkPrimaryContainer = Color(0xFF6D28D9);
  static const darkOnPrimaryContainer = Color(0xFFF3E8FF);

  static const darkSecondary = Color(0xFFF472B6);
  static const darkOnSecondary = Color(0xFF9D174D);

  static const darkSecondaryContainer = Color(0xFF3A1023);
  static const darkOnSecondaryContainer = Color(0xFFFBCFE8);

  static const darkTertiary = Color(0xFF2DD4BF);
  static const darkOnTertiary = Color(0xFF115E59);

  static const darkTertiaryContainer = Color(0xFF073B35);
  static const darkOnTertiaryContainer = Color(0xFF99F6E4);

  static const darkError = Color(0xFFFCA5A5);
  static const darkOnError = Color(0xFF991B1B);
  static const darkErrorContainer = Color(0xFFDC2626);
  static const darkOnErrorContainer = Color(0xFFFEE2E2);

  // Cosmic midnight surface family (avoid flat black)
  static const darkSurface = TruLuraBrandColors.midnightA;
  static const darkOnSurface = TruLuraBrandColors.textSoftWhite;
  static const darkSurfaceVariant = Color(0xFF0A1330);
  static const darkOnSurfaceVariant = TruLuraBrandColors.textLavenderGray;

  static const darkSurfaceTint = Color(0xFFA78BFA);

  static const darkOutline = Color(0xFF4B5563);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF7C3AED);
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// =============================================================================
// THEMES
// =============================================================================

/// Light theme with modern, neutral aesthetic
ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme.light(
        primary: LightModeColors.lightPrimary,
        onPrimary: LightModeColors.lightOnPrimary,
        primaryContainer: LightModeColors.lightPrimaryContainer,
        onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
        secondary: LightModeColors.lightSecondary,
        onSecondary: LightModeColors.lightOnSecondary,
        secondaryContainer: LightModeColors.lightSecondaryContainer,
        onSecondaryContainer: LightModeColors.lightOnSecondaryContainer,
        tertiary: LightModeColors.lightTertiary,
        onTertiary: LightModeColors.lightOnTertiary,
        tertiaryContainer: LightModeColors.lightTertiaryContainer,
        onTertiaryContainer: LightModeColors.lightOnTertiaryContainer,
        error: LightModeColors.lightError,
        onError: LightModeColors.lightOnError,
        errorContainer: LightModeColors.lightErrorContainer,
        onErrorContainer: LightModeColors.lightOnErrorContainer,
        surface: LightModeColors.lightSurface,
        onSurface: LightModeColors.lightOnSurface,
        surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
        onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
        outline: LightModeColors.lightOutline,
        shadow: LightModeColors.lightShadow,
        surfaceTint: LightModeColors.lightSurfaceTint,
        inversePrimary: LightModeColors.lightInversePrimary,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightModeColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: LightModeColors.lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
              color: LightModeColors.lightOutline.withValues(alpha: 0.22),
              width: TruLuraSurfaces.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LightModeColors.lightSurfaceVariant,
        selectedColor: LightModeColors.lightPrimaryContainer,
        secondarySelectedColor: LightModeColors.lightSecondaryContainer,
        labelStyle: _buildTextTheme(Brightness.light)
            .labelLarge
            ?.copyWith(color: LightModeColors.lightOnSurface),
        secondaryLabelStyle: _buildTextTheme(Brightness.light)
            .labelLarge
            ?.copyWith(
                color: LightModeColors.lightOnPrimaryContainer,
                fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const StadiumBorder(),
        side: BorderSide(
            color: LightModeColors.lightOutline.withValues(alpha: 0.18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: LightModeColors.lightOnPrimary,
          backgroundColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: LightModeColors.lightSurface.withValues(alpha: 0.92),
        indicatorColor: LightModeColors.lightPrimaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
            _buildTextTheme(Brightness.light).labelSmall),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: _buildTextTheme(Brightness.light)
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: _buildTextTheme(Brightness.light)
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightModeColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: LightModeColors.lightPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );

/// Dark theme with good contrast and readability
ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme.dark(
        primary: DarkModeColors.darkPrimary,
        onPrimary: DarkModeColors.darkOnPrimary,
        primaryContainer: DarkModeColors.darkPrimaryContainer,
        onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
        secondary: DarkModeColors.darkSecondary,
        onSecondary: DarkModeColors.darkOnSecondary,
        secondaryContainer: DarkModeColors.darkSecondaryContainer,
        onSecondaryContainer: DarkModeColors.darkOnSecondaryContainer,
        tertiary: DarkModeColors.darkTertiary,
        onTertiary: DarkModeColors.darkOnTertiary,
        tertiaryContainer: DarkModeColors.darkTertiaryContainer,
        onTertiaryContainer: DarkModeColors.darkOnTertiaryContainer,
        error: DarkModeColors.darkError,
        onError: DarkModeColors.darkOnError,
        errorContainer: DarkModeColors.darkErrorContainer,
        onErrorContainer: DarkModeColors.darkOnErrorContainer,
        surface: DarkModeColors.darkSurface,
        onSurface: DarkModeColors.darkOnSurface,
        surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
        onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
        outline: DarkModeColors.darkOutline,
        shadow: DarkModeColors.darkShadow,
        surfaceTint: DarkModeColors.darkSurfaceTint,
        inversePrimary: DarkModeColors.darkInversePrimary,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkModeColors.darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DarkModeColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: DarkModeColors.darkSurfaceVariant
            .withValues(alpha: TruLuraSurfaces.glassDarkA),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: TruLuraSurfaces.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DarkModeColors.darkSurfaceVariant,
        selectedColor: DarkModeColors.darkPrimaryContainer,
        secondarySelectedColor: DarkModeColors.darkSecondaryContainer,
        labelStyle: _buildTextTheme(Brightness.dark)
            .labelLarge
            ?.copyWith(color: DarkModeColors.darkOnSurface),
        secondaryLabelStyle: _buildTextTheme(Brightness.dark)
            .labelLarge
            ?.copyWith(
                color: DarkModeColors.darkOnPrimaryContainer,
                fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const StadiumBorder(),
        side: BorderSide(
            color: DarkModeColors.darkOutline.withValues(alpha: 0.22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: DarkModeColors.darkOnPrimary,
          backgroundColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: DarkModeColors.darkSurface.withValues(alpha: 0.86),
        indicatorColor:
            DarkModeColors.darkPrimaryContainer.withValues(alpha: 0.75),
        labelTextStyle:
            WidgetStatePropertyAll(_buildTextTheme(Brightness.dark).labelSmall),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: _buildTextTheme(Brightness.dark)
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: _buildTextTheme(Brightness.dark)
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Match glass fields in reference (slightly translucent, blurred by parent).
        fillColor: TruLuraBrandColors.glassFillStrong,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: DarkModeColors.darkPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      textTheme: _buildTextTheme(Brightness.dark),
    );

ThemeData get neutralTheme {
  final base = lightTheme;
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: const Color(0xFF5B6578),
      secondary: const Color(0xFF7A8798),
      tertiary: const Color(0xFF909DAE),
      surface: const Color(0xFFF5F6F8),
      surfaceContainerHighest: const Color(0xFFE8EBF0),
      onSurface: const Color(0xFF1D2430),
      onSurfaceVariant: const Color(0xFF566172),
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F3F6),
  );
}

ThemeData get plainDarkTheme {
  final base = darkTheme;
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      surface: const Color(0xFF12141B),
      surfaceContainerHighest: const Color(0xFF1A1E28),
      onSurfaceVariant: const Color(0xFFABB2C4),
    ),
    scaffoldBackgroundColor: const Color(0xFF12141B),
  );
}

/// Build text theme using Inter font family
TextTheme _buildTextTheme(Brightness brightness) {
  // Locked TruLura vibe: wide/spacey titles + clean body.
  final titleFont = GoogleFonts.spaceGrotesk;
  final bodyFont = GoogleFonts.inter;
  return TextTheme(
    displayLarge: titleFont(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    displayMedium: titleFont(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: titleFont(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: titleFont(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineMedium: titleFont(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w800,
    ),
    headlineSmall: titleFont(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w800,
    ),
    titleLarge: titleFont(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleMedium: titleFont(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: titleFont(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w700,
    ),
    labelLarge: bodyFont(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelMedium: bodyFont(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelSmall: bodyFont(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodyLarge: bodyFont(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodyMedium: bodyFont(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodySmall: bodyFont(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
  );
}
