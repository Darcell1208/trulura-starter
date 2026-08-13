enum TruEmotionalPresenceKind {
  emotionallyOpen,
  lowEnergy,
  sociallyOverwhelmed,
  softPresence,
  quietMode,
  glowingSocially,
  reflective,
  recharge,
  hidden,
}

class TruEmotionalPresenceState {
  final TruEmotionalPresenceKind kind;
  final String label;
  final double motionScale;
  final double glowScale;
  final double feedIntensityCap;
  final double silenceSpacing;
  final double warmth;
  final double recommendationSoftening;
  final double gravitySensitivity;
  final double organicTexture;
  final double touchSoftness;
  final double emotionalTemperature;
  final double afterglow;
  final double cooldown;

  const TruEmotionalPresenceState({
    required this.kind,
    required this.label,
    required this.motionScale,
    required this.glowScale,
    required this.feedIntensityCap,
    required this.silenceSpacing,
    required this.warmth,
    required this.recommendationSoftening,
    required this.gravitySensitivity,
    required this.organicTexture,
    required this.touchSoftness,
    required this.emotionalTemperature,
    required this.afterglow,
    required this.cooldown,
  });

  bool get isRestorative =>
      kind == TruEmotionalPresenceKind.lowEnergy ||
      kind == TruEmotionalPresenceKind.sociallyOverwhelmed ||
      kind == TruEmotionalPresenceKind.quietMode ||
      kind == TruEmotionalPresenceKind.recharge ||
      kind == TruEmotionalPresenceKind.hidden;

  static TruEmotionalPresenceState derive({
    required bool softMode,
    required bool lowEnergy,
    required bool anonymous,
    required String vibe,
    required Iterable<String> moods,
  }) {
    final text = '$vibe ${moods.join(' ')}'.toLowerCase();
    if (anonymous) {
      return presets[TruEmotionalPresenceKind.hidden]!;
    }
    if (lowEnergy && softMode) {
      return presets[TruEmotionalPresenceKind.recharge]!;
    }
    if (lowEnergy) {
      return presets[TruEmotionalPresenceKind.lowEnergy]!;
    }
    if (softMode) {
      return presets[TruEmotionalPresenceKind.quietMode]!;
    }
    if (text.contains('overwhelm') ||
        text.contains('anx') ||
        text.contains('tired') ||
        text.contains('burn')) {
      return presets[TruEmotionalPresenceKind.sociallyOverwhelmed]!;
    }
    if (text.contains('reflect') ||
        text.contains('old soul') ||
        text.contains('quiet') ||
        text.contains('ground')) {
      return presets[TruEmotionalPresenceKind.reflective]!;
    }
    if (text.contains('radiant') ||
        text.contains('social') ||
        text.contains('party') ||
        text.contains('spark')) {
      return presets[TruEmotionalPresenceKind.glowingSocially]!;
    }
    if (text.contains('heal') || text.contains('calm')) {
      return presets[TruEmotionalPresenceKind.softPresence]!;
    }
    return presets[TruEmotionalPresenceKind.emotionallyOpen]!;
  }

  static const Map<TruEmotionalPresenceKind, TruEmotionalPresenceState>
      presets = {
    TruEmotionalPresenceKind.emotionallyOpen: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.emotionallyOpen,
      label: 'emotionally open',
      motionScale: 0.92,
      glowScale: 0.94,
      feedIntensityCap: 0.82,
      silenceSpacing: 1.00,
      warmth: 0.74,
      recommendationSoftening: 0.12,
      gravitySensitivity: 0.58,
      organicTexture: 0.52,
      touchSoftness: 0.72,
      emotionalTemperature: 0.58,
      afterglow: 0.48,
      cooldown: 0.22,
    ),
    TruEmotionalPresenceKind.lowEnergy: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.lowEnergy,
      label: 'low energy',
      motionScale: 0.54,
      glowScale: 0.48,
      feedIntensityCap: 0.42,
      silenceSpacing: 1.22,
      warmth: 0.68,
      recommendationSoftening: 0.42,
      gravitySensitivity: 0.76,
      organicTexture: 0.64,
      touchSoftness: 0.88,
      emotionalTemperature: 0.42,
      afterglow: 0.62,
      cooldown: 0.62,
    ),
    TruEmotionalPresenceKind.sociallyOverwhelmed: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.sociallyOverwhelmed,
      label: 'socially overwhelmed',
      motionScale: 0.46,
      glowScale: 0.38,
      feedIntensityCap: 0.34,
      silenceSpacing: 1.34,
      warmth: 0.76,
      recommendationSoftening: 0.55,
      gravitySensitivity: 0.88,
      organicTexture: 0.70,
      touchSoftness: 0.94,
      emotionalTemperature: 0.46,
      afterglow: 0.70,
      cooldown: 0.76,
    ),
    TruEmotionalPresenceKind.softPresence: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.softPresence,
      label: 'soft presence',
      motionScale: 0.64,
      glowScale: 0.58,
      feedIntensityCap: 0.58,
      silenceSpacing: 1.16,
      warmth: 0.82,
      recommendationSoftening: 0.32,
      gravitySensitivity: 0.74,
      organicTexture: 0.68,
      touchSoftness: 0.86,
      emotionalTemperature: 0.64,
      afterglow: 0.74,
      cooldown: 0.54,
    ),
    TruEmotionalPresenceKind.quietMode: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.quietMode,
      label: 'quiet mode',
      motionScale: 0.42,
      glowScale: 0.34,
      feedIntensityCap: 0.38,
      silenceSpacing: 1.28,
      warmth: 0.72,
      recommendationSoftening: 0.48,
      gravitySensitivity: 0.82,
      organicTexture: 0.62,
      touchSoftness: 0.92,
      emotionalTemperature: 0.40,
      afterglow: 0.66,
      cooldown: 0.72,
    ),
    TruEmotionalPresenceKind.glowingSocially: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.glowingSocially,
      label: 'glowing socially',
      motionScale: 1.02,
      glowScale: 1.04,
      feedIntensityCap: 0.86,
      silenceSpacing: 0.94,
      warmth: 0.86,
      recommendationSoftening: 0.08,
      gravitySensitivity: 0.50,
      organicTexture: 0.58,
      touchSoftness: 0.66,
      emotionalTemperature: 0.78,
      afterglow: 0.54,
      cooldown: 0.12,
    ),
    TruEmotionalPresenceKind.reflective: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.reflective,
      label: 'reflective state',
      motionScale: 0.58,
      glowScale: 0.52,
      feedIntensityCap: 0.52,
      silenceSpacing: 1.24,
      warmth: 0.70,
      recommendationSoftening: 0.38,
      gravitySensitivity: 0.80,
      organicTexture: 0.72,
      touchSoftness: 0.90,
      emotionalTemperature: 0.34,
      afterglow: 0.72,
      cooldown: 0.58,
    ),
    TruEmotionalPresenceKind.recharge: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.recharge,
      label: 'recharge mode',
      motionScale: 0.36,
      glowScale: 0.28,
      feedIntensityCap: 0.30,
      silenceSpacing: 1.42,
      warmth: 0.78,
      recommendationSoftening: 0.62,
      gravitySensitivity: 0.92,
      organicTexture: 0.58,
      touchSoftness: 0.98,
      emotionalTemperature: 0.52,
      afterglow: 0.82,
      cooldown: 0.86,
    ),
    TruEmotionalPresenceKind.hidden: TruEmotionalPresenceState(
      kind: TruEmotionalPresenceKind.hidden,
      label: 'hidden mode',
      motionScale: 0.48,
      glowScale: 0.36,
      feedIntensityCap: 0.36,
      silenceSpacing: 1.36,
      warmth: 0.74,
      recommendationSoftening: 0.58,
      gravitySensitivity: 0.86,
      organicTexture: 0.76,
      touchSoftness: 0.96,
      emotionalTemperature: 0.44,
      afterglow: 0.78,
      cooldown: 0.80,
    ),
  };
}
