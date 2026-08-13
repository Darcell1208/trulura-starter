import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/emotional_presence_state.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';

/// A soft, layered background for TruLura screens.
///
/// Use it as a wrapper to avoid flat white pages and to give the UI
/// an expressive, emotional “social app” vibe.
class TruLuraLayeredBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final TruLuraModeTone tone;

  /// Optional palette mode override. If omitted, we derive a reasonable
  /// default from [tone].
  final TruLuraMode? mode;

  /// Optional mode-only accent overlay. Use for Sync's subtle rose tint.
  ///
  /// Must not be set globally.
  final Color? modeAccent;

  const TruLuraLayeredBackground(
      {super.key,
      required this.child,
      this.padding = EdgeInsets.zero,
      this.tone = TruLuraModeTone.aura,
      this.mode,
      this.modeAccent});

  TruLuraMode _modeForTone(TruLuraModeTone tone) {
    switch (tone) {
      case TruLuraModeTone.sync:
        return TruLuraMode.sync;
      case TruLuraModeTone.explore:
        return TruLuraMode.trending;
      case TruLuraModeTone.messages:
      case TruLuraModeTone.notifications:
      case TruLuraModeTone.profile:
        return TruLuraMode.social;
      case TruLuraModeTone.aura:
        return TruLuraMode.aura;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final softMode = app.softModeEnabled;
    final datingOnly = app.fullSyncModeEnabled;
    final presence = app.emotionalPresenceState;

    final selectedMode = mode ?? _modeForTone(tone);
    final personality = _AtmospherePersonality.forMode(selectedMode, tone);
    // Palette is derived from the mode requested by the screen.
    // Note: we intentionally do NOT mutate any provider during build.
    final palette = kTruLuraPalettes[selectedMode]!;

    final (toneA, toneB) = tone.resolve(cs);
    final auraBoost = switch (tone) {
      TruLuraModeTone.sync => 1.18,
      TruLuraModeTone.explore => 1.08,
      TruLuraModeTone.messages => 1.00,
      TruLuraModeTone.notifications => 1.04,
      TruLuraModeTone.profile => 1.10,
      TruLuraModeTone.aura => 0.98,
    };

    // LOCKED: Background is a layered atmosphere (not a single flat gradient).
    // We keep a subtle vertical underlay to avoid flat black.
    final baseGradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.bg0, palette.bg1, palette.bg0])
        : TruLuraGradients.softSurface(brightness);

    // Micro-stars: cinematic 6–8% max, soft 2–3%.
    final starOpacity = brightness == Brightness.dark
        ? (softMode ? 0.028 : 0.082) * personality.sparkleScale
        : 0.0;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: baseGradient),
      // Provide a Material ancestor so InkWell/TabBar ripple renderers don't
      // conflict when layered on a non-Material background.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (brightness == Brightness.dark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: TruLuraTokens.ink),
                  ),
                ),
              ),

            // Layer 2: Nebula haze (soft).
            if (brightness == Brightness.dark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.6, -0.4),
                        radius: 1.1,
                        // Ref: radial-gradient(circle at 20% 30%, rgba(40, 90, 255, 0.25), transparent 60%)
                        colors: [
                          palette.glowB.withValues(alpha: 0.22),
                          Colors.transparent
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (brightness == Brightness.dark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.7, 0.45),
                        radius: 1.05,
                        // Ref: radial-gradient(circle at 80% 70%, rgba(130, 70, 255, 0.18), transparent 60%)
                        colors: [
                          palette.glowA.withValues(alpha: 0.20),
                          Colors.transparent
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            // Micro rose dust (Sync spec mentions ~4%). Never a global wash.
            if (brightness == Brightness.dark && tone == TruLuraModeTone.sync)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.2, 0.6),
                        radius: 1.2,
                        colors: [
                          TruLuraBrandColors.syncRose
                              .withValues(alpha: softMode ? 0.018 : 0.04),
                          Colors.transparent
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

            // Layer 3: Micro-star field (very faint). Always present in dark mode.
            if (brightness == Brightness.dark)
              Positioned.fill(
                child: StarDustLayer(
                  tone: tone,
                  datingOnly: datingOnly,
                  opacity: starOpacity,
                ),
              ),

            // Optional subtle mode-only accent (Sync rose). Never global.
            if (brightness == Brightness.dark && modeAccent != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.35, 0.0),
                        radius: 1.25,
                        colors: [
                          modeAccent!.withValues(alpha: 0.18),
                          Colors.transparent
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

            // Cinematic layers (kept on even in Soft Mode, but attenuated).
            // These are deterministic (seeded) and intentionally subtle.
            Positioned.fill(
              child: TruLuraLivingAmbientLayer(
                tone: tone,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.34 : 1.0) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
                child: NebulaMistLayer(
                    enabled: brightness == Brightness.dark,
                    intensity: (softMode ? 0.38 : 1.0) *
                        personality.mistScale *
                        (presence.isRestorative ? 0.86 : 1.0))),
            Positioned.fill(
                child: TruLuraBokehLayer(
                    enabled: brightness == Brightness.dark,
                    intensity: (softMode ? 0.30 : 1.0) *
                        personality.bokehScale *
                        presence.glowScale)),
            Positioned.fill(
              child: TruLuraAtmosphereLayer(
                tone: tone,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.42 : 1.0) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
              child: TruLuraEmotionalWeatherLayer(
                tone: tone,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.30 : 1.0) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
              child: TruLuraWorldspaceLayer(
                tone: tone,
                mode: selectedMode,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.34 : 1.0) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
              child: TruLuraWorldPresenceLayer(
                tone: tone,
                mode: selectedMode,
                presence: presence,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.22 : 0.66) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
              child: TruLuraDepthFogLayer(
                tone: tone,
                mode: selectedMode,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.28 : 0.78) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
              child: TruLuraCinematicLightLayer(
                tone: tone,
                mode: selectedMode,
                presence: presence,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.24 : 0.74) *
                    personality.motionScale *
                    presence.motionScale,
              ),
            ),
            Positioned.fill(
              child: TruLuraInhabitedPresenceLayer(
                tone: tone,
                mode: selectedMode,
                enabled: brightness == Brightness.dark,
                intensity: (softMode ? 0.18 : 0.64) *
                    personality.motionScale *
                    (datingOnly ? 0.72 : 1.0),
              ),
            ),
            if (brightness == Brightness.dark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: personality.lightBegin,
                        end: personality.lightEnd,
                        colors: [
                          personality.accentA.withValues(
                            alpha: personality.overlayAlpha *
                                (softMode ? 0.44 : 1.0),
                          ),
                          Colors.transparent,
                          personality.accentB.withValues(
                            alpha: personality.overlayAlpha *
                                0.58 *
                                (softMode ? 0.42 : 1.0),
                          ),
                        ],
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (!softMode && brightness == Brightness.dark && !datingOnly)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.55, -0.30),
                        radius: 1.05,
                        colors: [
                          TruLuraBrandColors.neonBlue.withValues(alpha: 0.16),
                          TruLuraBrandColors.neonPurple.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
            if (brightness == Brightness.dark)
              const Positioned.fill(child: VignetteLayer()),
            // Grain/noise stays even in Soft Mode, just subtle.
            if (brightness == Brightness.dark)
              const Positioned.fill(child: FilmGrainLayer()),
            if (!softMode)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.surface.withValues(
                              alpha:
                                  brightness == Brightness.dark ? 0.06 : 0.55),
                          cs.surface.withValues(alpha: 0.0),
                          cs.surface.withValues(
                              alpha:
                                  brightness == Brightness.dark ? 0.12 : 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!softMode && brightness == Brightness.dark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.55, -0.6),
                        radius: 1.25,
                        colors: [
                          toneA.withValues(alpha: 0.16 * auraBoost),
                          toneB.withValues(alpha: 0.12 * auraBoost),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.52, 1],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VignetteLayer extends StatelessWidget {
  const _VignetteLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.25,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.66)
            ],
            stops: const [0.0, 0.72, 1.0],
          ),
        ),
      ),
    );
  }
}

class _FilmGrainLayer extends StatelessWidget {
  const _FilmGrainLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FilmGrainPainter(seed: 9),
      ),
    );
  }
}

// =============================================================================
// Public layer wrappers (so the widget tree reads like the TruLura design spec)
// =============================================================================

/// TruLura micro-star / light-dust layer.
class StarDustLayer extends StatelessWidget {
  final TruLuraModeTone tone;
  final bool datingOnly;
  final double opacity;

  const StarDustLayer(
      {super.key,
      required this.tone,
      required this.datingOnly,
      required this.opacity});

  @override
  Widget build(BuildContext context) =>
      _StarDustLayer(tone: tone, datingOnly: datingOnly, opacity: opacity);
}

/// TruLura nebula haze layer (cinematic screen-blended blobs).
class NebulaMistLayer extends StatelessWidget {
  final bool enabled;
  final double intensity;

  const NebulaMistLayer({super.key, this.enabled = true, this.intensity = 1.0});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    if (intensity <= 0) return const SizedBox.shrink();
    return Opacity(
        opacity: intensity.clamp(0.0, 1.0),
        child: const _CinematicNebulaMistLayer());
  }
}

/// TruLura soft glow blobs (bokeh) layer.
class TruLuraBokehLayer extends StatelessWidget {
  final bool enabled;
  final double intensity;

  const TruLuraBokehLayer(
      {super.key, this.enabled = true, this.intensity = 1.0});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    if (intensity <= 0) return const SizedBox.shrink();

    // Combine the deterministic screen-blend bokeh + the larger glow blobs.
    return Opacity(
      opacity: intensity.clamp(0.0, 1.0),
      child: const Stack(
        children: [
          Positioned.fill(child: _CinematicBokehLayer()),
          Positioned.fill(child: _TruLuraBokehLayer()),
        ],
      ),
    );
  }
}

/// TruLura vignette (cinematic edge darkening).
class VignetteLayer extends StatelessWidget {
  const VignetteLayer({super.key});

  @override
  Widget build(BuildContext context) => const _VignetteLayer();
}

/// TruLura film grain / noise.
class FilmGrainLayer extends StatelessWidget {
  const FilmGrainLayer({super.key});

  @override
  Widget build(BuildContext context) => const _FilmGrainLayer();
}

class TruLuraLivingAmbientLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final bool enabled;
  final double intensity;

  const TruLuraLivingAmbientLayer({
    super.key,
    required this.tone,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraLivingAmbientLayer> createState() =>
      _TruLuraLivingAmbientLayerState();
}

class _TruLuraLivingAmbientLayerState extends State<TruLuraLivingAmbientLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 34),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (a, b) = widget.tone.resolve(cs);
    final intensity = widget.intensity.clamp(0.0, 1.0);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          return CustomPaint(
            painter: _LivingAmbientPainter(
              progress: _breath.value,
              accentA: a,
              accentB: b,
              intensity: intensity,
            ),
          );
        },
      ),
    );
  }
}

class TruLuraWorldspaceLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final bool enabled;
  final double intensity;

  const TruLuraWorldspaceLayer({
    super.key,
    required this.tone,
    required this.mode,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraWorldspaceLayer> createState() => _TruLuraWorldspaceLayerState();
}

class TruLuraInhabitedPresenceLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final bool enabled;
  final double intensity;

  const TruLuraInhabitedPresenceLayer({
    super.key,
    required this.tone,
    required this.mode,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraInhabitedPresenceLayer> createState() =>
      _TruLuraInhabitedPresenceLayerState();
}

@immutable
class _WorldPresenceSpec {
  final Color anchorA;
  final Color anchorB;
  final double depth;
  final double shelter;
  final double curiosity;
  final double luxury;
  final Alignment horizon;

  const _WorldPresenceSpec({
    required this.anchorA,
    required this.anchorB,
    required this.depth,
    required this.shelter,
    required this.curiosity,
    required this.luxury,
    required this.horizon,
  });

  static _WorldPresenceSpec resolve(TruLuraMode mode, TruLuraModeTone tone) {
    switch (mode) {
      case TruLuraMode.sync:
        return const _WorldPresenceSpec(
          anchorA: TruLuraBrandColors.syncRose,
          anchorB: TruLuraBrandColors.cosmicPurple,
          depth: 0.78,
          shelter: 0.30,
          curiosity: 0.22,
          luxury: 0.36,
          horizon: Alignment(0.34, -0.20),
        );
      case TruLuraMode.vent:
        return const _WorldPresenceSpec(
          anchorA: TruLuraTokens.auraCyan,
          anchorB: TruLuraBrandColors.neonBlue,
          depth: 0.92,
          shelter: 1.0,
          curiosity: 0.08,
          luxury: 0.18,
          horizon: Alignment(0.0, 0.08),
        );
      case TruLuraMode.trending:
        return _WorldPresenceSpec(
          anchorA: tone == TruLuraModeTone.explore
              ? TruLuraBrandColors.glowGold
              : TruLuraTokens.auraPink,
          anchorB: TruLuraTokens.auraCyan,
          depth: 0.64,
          shelter: 0.18,
          curiosity: 0.92,
          luxury: 0.22,
          horizon: const Alignment(-0.32, -0.26),
        );
      case TruLuraMode.social:
        return const _WorldPresenceSpec(
          anchorA: TruLuraTokens.auraPink,
          anchorB: TruLuraTokens.auraCyan,
          depth: 0.58,
          shelter: 0.22,
          curiosity: 0.46,
          luxury: 0.26,
          horizon: Alignment(-0.18, -0.36),
        );
      case TruLuraMode.aura:
        return const _WorldPresenceSpec(
          anchorA: TruLuraBrandColors.neonBlue,
          anchorB: TruLuraBrandColors.neonPurple,
          depth: 0.84,
          shelter: 0.26,
          curiosity: 0.54,
          luxury: 0.20,
          horizon: Alignment(-0.26, -0.42),
        );
    }
  }
}

class TruLuraWorldPresenceLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final TruEmotionalPresenceState presence;
  final bool enabled;
  final double intensity;

  const TruLuraWorldPresenceLayer({
    super.key,
    required this.tone,
    required this.mode,
    required this.presence,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraWorldPresenceLayer> createState() =>
      _TruLuraWorldPresenceLayerState();
}

class _TruLuraWorldPresenceLayerState extends State<TruLuraWorldPresenceLayer>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _transition;
  late _WorldPresenceSpec _previousSpec;
  late _WorldPresenceSpec _currentSpec;

  @override
  void initState() {
    super.initState();
    _previousSpec = _WorldPresenceSpec.resolve(widget.mode, widget.tone);
    _currentSpec = _previousSpec;
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 64),
    )..repeat();
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant TruLuraWorldPresenceLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _WorldPresenceSpec.resolve(widget.mode, widget.tone);
    if (oldWidget.mode != widget.mode || oldWidget.tone != widget.tone) {
      _previousSpec = _currentSpec;
      _currentSpec = next;
      _transition.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _transition]),
        builder: (context, _) {
          return CustomPaint(
            painter: _WorldPresencePainter(
              progress: _breath.value,
              previous: _previousSpec,
              current: _currentSpec,
              continuity: Curves.easeInOutCubic.transform(_transition.value),
              presence: widget.presence,
              intensity: widget.intensity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _WorldPresencePainter extends CustomPainter {
  final double progress;
  final _WorldPresenceSpec previous;
  final _WorldPresenceSpec current;
  final double continuity;
  final TruEmotionalPresenceState presence;
  final double intensity;

  const _WorldPresencePainter({
    required this.progress,
    required this.previous,
    required this.current,
    required this.continuity,
    required this.presence,
    required this.intensity,
  });

  Color _blend(Color a, Color b) =>
      Color.lerp(a, b, continuity.clamp(0.0, 1.0)) ?? b;

  double _lerp(double a, double b) => a + (b - a) * continuity.clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final inhale = 0.5 + math.sin(phase * 0.72) * 0.5;
    final pulse = 0.5 + math.sin(phase * 0.43 + 1.6) * 0.5;
    final anchorA = _blend(previous.anchorA, current.anchorA);
    final anchorB = _blend(previous.anchorB, current.anchorB);
    final depth = _lerp(previous.depth, current.depth);
    final shelter = _lerp(previous.shelter, current.shelter);
    final curiosity = _lerp(previous.curiosity, current.curiosity);
    final luxury = _lerp(previous.luxury, current.luxury);
    final temp = presence.emotionalTemperature.clamp(0.0, 1.0);
    final warmth = Color.lerp(anchorA, TruLuraBrandColors.glowGold, temp);
    final cool = Color.lerp(anchorB, TruLuraTokens.auraCyan, 1 - temp);
    final organic = presence.organicTexture;

    final horizonPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        center: Alignment(
          current.horizon.x + math.sin(phase * 0.31) * 0.04 * organic,
          current.horizon.y + math.cos(phase * 0.27) * 0.035 * organic,
        ),
        radius: 0.70 + depth * 0.34 + inhale * 0.06,
        colors: [
          (warmth ?? anchorA).withValues(
              alpha: (0.036 + curiosity * 0.020 + temp * 0.010) * intensity),
          (cool ?? anchorB).withValues(alpha: 0.026 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.44, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, horizonPaint);

    final shelterPaint = Paint()
      ..blendMode = BlendMode.srcOver
      ..shader = RadialGradient(
        center: Alignment(0.0, 0.74 - pulse * 0.10),
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.08 * shelter * intensity),
          Colors.black.withValues(alpha: 0.26 * shelter * intensity),
        ],
        stops: const [0.0, 0.68, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, shelterPaint);

    final afterglowPaint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + math.sin(phase * 0.23) * 0.08, -0.8),
        end: Alignment(1.0, 0.85 - math.cos(phase * 0.19) * 0.05),
        colors: [
          Colors.transparent,
          anchorA.withValues(alpha: 0.022 * presence.afterglow * intensity),
          Colors.white.withValues(alpha: 0.006 * intensity),
          anchorB.withValues(alpha: 0.018 * presence.afterglow * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.50, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, afterglowPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8 + luxury * 0.5
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          anchorA.withValues(alpha: 0.050 * intensity),
          anchorB.withValues(alpha: 0.030 * intensity),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    for (var i = 0; i < 3; i++) {
      final y = size.height *
          (0.22 + i * (0.18 + shelter * 0.04) + math.sin(phase + i) * 0.010);
      final path = Path()
        ..moveTo(size.width * -0.08, y)
        ..cubicTo(
          size.width * (0.22 + organic * 0.04),
          y - (12 + depth * 10),
          size.width * (0.68 - organic * 0.03),
          y + (14 + curiosity * 8),
          size.width * 1.08,
          y - 3,
        );
      canvas.drawPath(path, linePaint);
    }

    final memoryPaint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 9; i++) {
      final seed = i * 47.0;
      final x = (math.sin(seed + phase * (0.08 + i * 0.003)) * 0.5 + 0.5) *
          size.width;
      final y = (math.cos(seed * 0.7 + phase * 0.06) * 0.5 + 0.5) * size.height;
      final alpha = (0.010 + (i % 3) * 0.003) * intensity * presence.afterglow;
      memoryPaint.color =
          (i.isEven ? anchorA : anchorB).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 3.5 + (i % 4) * 1.2, memoryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldPresencePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.previous != previous ||
        oldDelegate.current != current ||
        oldDelegate.continuity != continuity ||
        oldDelegate.presence != presence ||
        oldDelegate.intensity != intensity;
  }
}

class TruLuraCinematicLightLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final TruEmotionalPresenceState presence;
  final bool enabled;
  final double intensity;

  const TruLuraCinematicLightLayer({
    super.key,
    required this.tone,
    required this.mode,
    required this.presence,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraCinematicLightLayer> createState() =>
      _TruLuraCinematicLightLayerState();
}

class _TruLuraCinematicLightLayerState extends State<TruLuraCinematicLightLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _camera;

  @override
  void initState() {
    super.initState();
    _camera = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 52),
    )..repeat();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (toneA, toneB) = widget.tone.resolve(cs);
    final p = kTruLuraPalettes[widget.mode]!;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _camera,
        builder: (context, _) {
          return CustomPaint(
            painter: _CinematicLightPainter(
              progress: _camera.value,
              tone: widget.tone,
              mode: widget.mode,
              presence: widget.presence,
              accentA: Color.alphaBlend(toneA.withValues(alpha: 0.48), p.glowA),
              accentB: Color.alphaBlend(toneB.withValues(alpha: 0.42), p.glowB),
              intensity: widget.intensity.clamp(0.0, 1.0),
              hour: DateTime.now().hour,
            ),
          );
        },
      ),
    );
  }
}

class _CinematicLightPainter extends CustomPainter {
  final double progress;
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final TruEmotionalPresenceState presence;
  final Color accentA;
  final Color accentB;
  final double intensity;
  final int hour;

  const _CinematicLightPainter({
    required this.progress,
    required this.tone,
    required this.mode,
    required this.presence,
    required this.accentA,
    required this.accentB,
    required this.intensity,
    required this.hour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final focus = 0.5 + math.sin(phase * 0.72) * 0.5;
    final warmth = presence.warmth.clamp(0.0, 1.0);
    final organic = presence.organicTexture.clamp(0.0, 1.0);
    final irregular = math.sin(phase * 1.37 + mode.index) * 0.018 * organic +
        math.cos(phase * 0.73 + tone.index) * 0.014 * organic;
    final night = hour >= 21 || hour <= 5;
    final sunrise = hour >= 5 && hour <= 8;
    final warmthColor = sunrise || mode == TruLuraMode.sync
        ? TruLuraBrandColors.syncRose
        : night
            ? TruLuraBrandColors.glowGold
            : accentA;

    final bloom = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        center:
            Alignment(-0.58 + focus * 0.20 + irregular, -0.82 + focus * 0.12),
        radius: 0.82 + focus * 0.16 + organic * 0.035,
        colors: [
          warmthColor.withValues(alpha: 0.040 * intensity * warmth),
          accentB.withValues(alpha: 0.022 * intensity),
          Colors.transparent,
        ],
        stops: const [0, 0.42, 1],
      ).createShader(rect);
    canvas.drawRect(rect, bloom);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0 + organic * 0.55
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment(-1 + focus * 0.22, -1),
        end: Alignment(1, 1 - focus * 0.18),
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: 0.070 * intensity),
          Colors.white.withValues(alpha: 0.018 * intensity),
          accentB.withValues(alpha: 0.045 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.48, 0.70, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    final edgePath = Path()
      ..moveTo(
          size.width * (0.04 + irregular), size.height * (0.16 + focus * 0.06))
      ..cubicTo(
        size.width * 0.28,
        size.height * (0.04 + organic * 0.025),
        size.width * (0.62 + irregular),
        size.height * 0.28,
        size.width * 0.96,
        size.height * (0.12 + focus * 0.08),
      );
    canvas.drawPath(edgePath, edge);

    final contrast = Paint()
      ..blendMode = BlendMode.srcOver
      ..shader = RadialGradient(
        center: Alignment(0.1 - focus * 0.1, 0.08 + focus * 0.10),
        radius: presence.isRestorative ? 1.30 : 1.08,
        colors: [
          Colors.transparent,
          Colors.black.withValues(
              alpha: (presence.isRestorative ? 0.10 : 0.065) * intensity),
          Colors.black.withValues(alpha: 0.20 * intensity),
        ],
        stops: const [0.0, 0.74, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, contrast);

    if (night) {
      final moonlight = Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment(-0.8 + math.sin(phase) * 0.08, -1),
          end: const Alignment(0.5, 1),
          colors: [
            const Color(0xFFB8C8FF).withValues(alpha: 0.030 * intensity),
            Colors.transparent,
          ],
        ).createShader(rect);
      canvas.drawRect(rect, moonlight);
    }

    final texture = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 7; i++) {
      final seed = i * 19.0 + mode.index * 11;
      final x = (math.sin(seed + phase * (0.16 + i * 0.009)) * 0.5 + 0.5) *
          size.width;
      final y = (math.cos(seed * 0.6 + phase * 0.11) * 0.5 + 0.5) * size.height;
      texture.color = (i.isEven ? accentA : warmthColor)
          .withValues(alpha: 0.010 * intensity * organic);
      canvas.drawCircle(Offset(x, y), 12 + i * 3.0, texture);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicLightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tone != tone ||
        oldDelegate.mode != mode ||
        oldDelegate.presence != presence ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity ||
        oldDelegate.hour != hour;
  }
}

class TruLuraDepthFogLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final bool enabled;
  final double intensity;

  const TruLuraDepthFogLayer({
    super.key,
    required this.tone,
    required this.mode,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraDepthFogLayer> createState() => _TruLuraDepthFogLayerState();
}

class _TruLuraDepthFogLayerState extends State<TruLuraDepthFogLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _depth;

  @override
  void initState() {
    super.initState();
    _depth = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 58),
    )..repeat();
  }

  @override
  void dispose() {
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (toneA, toneB) = widget.tone.resolve(cs);
    final p = kTruLuraPalettes[widget.mode]!;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _depth,
        builder: (context, _) {
          return CustomPaint(
            painter: _DepthFogPainter(
              progress: _depth.value,
              tone: widget.tone,
              mode: widget.mode,
              accentA: Color.alphaBlend(toneA.withValues(alpha: 0.50), p.glowA),
              accentB: Color.alphaBlend(toneB.withValues(alpha: 0.46), p.glowB),
              intensity: widget.intensity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _DepthFogPainter extends CustomPainter {
  final double progress;
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final Color accentA;
  final Color accentB;
  final double intensity;

  const _DepthFogPainter({
    required this.progress,
    required this.tone,
    required this.mode,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final breath = 0.5 + math.sin(phase) * 0.5;
    final compression = mode == TruLuraMode.vent ? 1.35 : 1.0;
    final blur = mode == TruLuraMode.vent ? 42.0 : 30.0;

    final fogPaint = Paint()
      ..blendMode = BlendMode.screen
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    void fogRibbon({
      required double y,
      required Color color,
      required double alpha,
      required double wave,
      required double width,
    }) {
      fogPaint
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            color.withValues(alpha: alpha * intensity),
            Colors.white.withValues(alpha: alpha * 0.16 * intensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.55, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * compression
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(-size.width * 0.12, size.height * y)
        ..cubicTo(
          size.width * 0.22,
          size.height * (y - wave + breath * 0.025),
          size.width * 0.68,
          size.height * (y + wave - breath * 0.020),
          size.width * 1.12,
          size.height * (y - wave * 0.45),
        );
      canvas.drawPath(path, fogPaint);
    }

    fogRibbon(
      y: tone == TruLuraModeTone.sync ? 0.22 : 0.28,
      color: accentA,
      alpha: 0.030,
      wave: 0.080,
      width: size.shortestSide * 0.12,
    );
    fogRibbon(
      y: mode == TruLuraMode.vent ? 0.62 : 0.70,
      color: accentB,
      alpha: mode == TruLuraMode.vent ? 0.020 : 0.026,
      wave: 0.060,
      width: size.shortestSide * 0.16,
    );

    final geometryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..blendMode = BlendMode.plus
      ..color = accentA.withValues(alpha: 0.030 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.15 + i * 0.24 + math.sin(phase + i) * 0.018);
      final y = size.height * (0.20 + (i % 2) * 0.48 + breath * 0.030);
      final r = size.shortestSide * (0.075 + i * 0.012);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: r * 1.8, height: r),
          Radius.circular(r * 0.28),
        ),
        geometryPaint,
      );
    }

    final foreground = Paint()
      ..blendMode = BlendMode.srcOver
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.055 * intensity),
          Colors.black.withValues(alpha: 0.18 * intensity),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, foreground);
  }

  @override
  bool shouldRepaint(covariant _DepthFogPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tone != tone ||
        oldDelegate.mode != mode ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

class _TruLuraInhabitedPresenceLayerState
    extends State<TruLuraInhabitedPresenceLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 38),
    )..repeat();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (toneA, toneB) = widget.tone.resolve(cs);
    final palette = kTruLuraPalettes[widget.mode]!;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _life,
        builder: (context, _) {
          return CustomPaint(
            painter: _PresenceEchoPainter(
              progress: _life.value,
              tone: widget.tone,
              accentA: Color.alphaBlend(
                  toneA.withValues(alpha: 0.48), palette.glowA),
              accentB: Color.alphaBlend(
                  toneB.withValues(alpha: 0.42), palette.glowB),
              intensity: widget.intensity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _PresenceEchoPainter extends CustomPainter {
  final double progress;
  final TruLuraModeTone tone;
  final Color accentA;
  final Color accentB;
  final double intensity;

  const _PresenceEchoPainter({
    required this.progress,
    required this.tone,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = progress * math.pi * 2;
    final socialLift = switch (tone) {
      TruLuraModeTone.explore => 1.24,
      TruLuraModeTone.sync => 0.96,
      TruLuraModeTone.messages => 1.08,
      TruLuraModeTone.notifications => 1.00,
      TruLuraModeTone.profile => 0.86,
      TruLuraModeTone.aura => 1.04,
    };
    final alpha = intensity * socialLift;
    final echoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    final dotPaint = Paint()..blendMode = BlendMode.plus;

    final anchors = <Offset>[
      Offset(size.width * 0.15, size.height * 0.24),
      Offset(size.width * 0.82, size.height * 0.30),
      Offset(size.width * 0.28, size.height * 0.70),
      Offset(size.width * 0.74, size.height * 0.78),
    ];

    for (var i = 0; i < anchors.length; i++) {
      final anchor = anchors[i];
      final pulse = 0.5 + math.sin(phase + i * 1.4) * 0.5;
      final color = i.isEven ? accentA : accentB;
      final radius = size.shortestSide * (0.034 + i * 0.006 + pulse * 0.010);
      echoPaint
        ..strokeWidth = 0.9
        ..color = color.withValues(alpha: (0.050 + pulse * 0.045) * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      canvas.drawCircle(anchor, radius, echoPaint);
      canvas.drawCircle(anchor, radius * 1.55, echoPaint);

      dotPaint.color = color.withValues(alpha: (0.10 + pulse * 0.10) * alpha);
      canvas.drawCircle(anchor, 1.5 + pulse * 1.2, dotPaint);
    }

    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: 0.048 * alpha),
          accentB.withValues(alpha: 0.036 * alpha),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * (0.50 + math.sin(phase) * 0.02))
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.36,
        size.width * 0.58,
        size.height * 0.72,
        size.width * 0.88,
        size.height * (0.48 + math.cos(phase * 0.8) * 0.02),
      );
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _PresenceEchoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tone != tone ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

class _TruLuraWorldspaceLayerState extends State<TruLuraWorldspaceLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 46),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (toneA, toneB) = widget.tone.resolve(cs);
    final p = kTruLuraPalettes[widget.mode]!;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          return CustomPaint(
            painter: _WorldspacePainter(
              progress: _drift.value,
              tone: widget.tone,
              mode: widget.mode,
              accentA: Color.alphaBlend(toneA.withValues(alpha: 0.62), p.glowA),
              accentB: Color.alphaBlend(toneB.withValues(alpha: 0.58), p.glowB),
              intensity: widget.intensity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _WorldspacePainter extends CustomPainter {
  final double progress;
  final TruLuraModeTone tone;
  final TruLuraMode mode;
  final Color accentA;
  final Color accentB;
  final double intensity;

  const _WorldspacePainter({
    required this.progress,
    required this.tone,
    required this.mode,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final drift = math.sin(phase) * 0.5 + 0.5;
    final modeBoost = switch (mode) {
      TruLuraMode.sync => 1.12,
      TruLuraMode.trending => 1.20,
      TruLuraMode.vent => 0.62,
      TruLuraMode.social => 0.86,
      TruLuraMode.aura => 0.96,
    };
    final alpha = intensity * modeBoost;

    final hazePaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment(-0.9 + drift * 0.14, -1),
        end: Alignment(0.8 - drift * 0.12, 1),
        colors: [
          accentA.withValues(alpha: 0.034 * alpha),
          Colors.transparent,
          accentB.withValues(alpha: 0.030 * alpha),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, hazePaint);

    void orbit({
      required Offset center,
      required Size orbitSize,
      required Color color,
      required double opacity,
      required double start,
      required double sweep,
      double strokeScale = 1.0,
    }) {
      final orbitRect = Rect.fromCenter(
        center: center,
        width: orbitSize.width,
        height: orbitSize.height,
      );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.shortestSide * 0.0014 * strokeScale)
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + math.pi * 2,
          colors: [
            Colors.transparent,
            color.withValues(alpha: opacity * alpha),
            Colors.white.withValues(alpha: opacity * 0.20 * alpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.36, 0.48, 1.0],
        ).createShader(orbitRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawArc(orbitRect, start + phase * 0.10, sweep, false, paint);
    }

    orbit(
      center: Offset(
          size.width * (tone == TruLuraModeTone.explore ? 0.62 : 0.34),
          size.height * 0.32),
      orbitSize: Size(size.width * 0.86, size.height * 0.34),
      color: accentA,
      opacity: 0.13,
      start: -math.pi * 0.92,
      sweep: math.pi * (tone == TruLuraModeTone.sync ? 0.78 : 0.62),
      strokeScale: tone == TruLuraModeTone.profile ? 1.25 : 1,
    );
    orbit(
      center: Offset(size.width * (0.72 - drift * 0.035),
          size.height * (tone == TruLuraModeTone.sync ? 0.58 : 0.68)),
      orbitSize: Size(size.width * 0.68, size.height * 0.42),
      color: accentB,
      opacity: tone == TruLuraModeTone.aura ? 0.12 : 0.095,
      start: math.pi * 0.18,
      sweep: math.pi * 0.58,
      strokeScale: 0.88,
    );

    final dustPaint = Paint()..blendMode = BlendMode.plus;
    final count = mode == TruLuraMode.trending ? 16 : 11;
    for (var i = 0; i < count; i++) {
      final seed = i * 41.0;
      final x = (math.sin(seed + phase * (0.16 + i * 0.002)) * 0.5 + 0.5) *
          size.width;
      final y = (math.cos(seed * 0.7 + phase * 0.11) * 0.5 + 0.5) * size.height;
      final r = 0.8 + (i % 4) * 0.45;
      dustPaint.color = (i.isEven ? accentA : accentB)
          .withValues(alpha: (0.050 + (i % 3) * 0.012) * alpha);
      canvas.drawCircle(Offset(x, y), r, dustPaint);
    }

    final bottomFog = Paint()
      ..blendMode = BlendMode.srcOver
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black
              .withValues(alpha: mode == TruLuraMode.vent ? 0.30 : 0.18),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bottomFog);
  }

  @override
  bool shouldRepaint(covariant _WorldspacePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tone != tone ||
        oldDelegate.mode != mode ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

class _LivingAmbientPainter extends CustomPainter {
  final double progress;
  final Color accentA;
  final Color accentB;
  final double intensity;

  const _LivingAmbientPainter({
    required this.progress,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = progress * math.pi * 2;
    final breathe = 0.5 + math.sin(phase) * 0.5;
    final drift = math.sin(phase * 0.62);
    final paint = Paint()..blendMode = BlendMode.screen;

    void glow(Offset center, double radius, Color color, double alpha) {
      paint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * intensity),
          color.withValues(alpha: alpha * 0.22 * intensity),
          Colors.transparent,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    glow(
      Offset(size.width * (0.18 + drift * 0.035),
          size.height * (0.22 + breathe * 0.030)),
      size.longestSide * 0.46,
      accentA,
      0.088,
    );
    glow(
      Offset(size.width * (0.82 - drift * 0.030),
          size.height * (0.74 - breathe * 0.026)),
      size.longestSide * 0.52,
      accentB,
      0.076,
    );

    paint.shader = LinearGradient(
      begin: Alignment(-1 + drift * 0.16, -1),
      end: Alignment(1 - drift * 0.12, 1),
      colors: [
        Colors.white.withValues(alpha: 0.016 * intensity),
        accentA.withValues(alpha: 0.034 * intensity),
        Colors.transparent,
        accentB.withValues(alpha: 0.028 * intensity),
      ],
      stops: const [0.0, 0.25, 0.62, 1.0],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _LivingAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

@immutable
class _AtmospherePersonality {
  final double mistScale;
  final double bokehScale;
  final double sparkleScale;
  final double motionScale;
  final double overlayAlpha;
  final Color accentA;
  final Color accentB;
  final Alignment lightBegin;
  final Alignment lightEnd;

  const _AtmospherePersonality({
    required this.mistScale,
    required this.bokehScale,
    required this.sparkleScale,
    required this.motionScale,
    required this.overlayAlpha,
    required this.accentA,
    required this.accentB,
    required this.lightBegin,
    required this.lightEnd,
  });

  static _AtmospherePersonality forMode(
    TruLuraMode mode,
    TruLuraModeTone tone,
  ) {
    final (toneA, toneB) = tone.resolve(const ColorScheme.dark());
    switch (mode) {
      case TruLuraMode.sync:
        return _AtmospherePersonality(
          mistScale: 0.88,
          bokehScale: 0.76,
          sparkleScale: 0.72,
          motionScale: 0.72,
          overlayAlpha: 0.075,
          accentA: TruLuraBrandColors.syncRose,
          accentB: TruLuraBrandColors.cosmicPurple,
          lightBegin: const Alignment(-0.8, -1),
          lightEnd: const Alignment(0.8, 1),
        );
      case TruLuraMode.vent:
        return _AtmospherePersonality(
          mistScale: 0.54,
          bokehScale: 0.38,
          sparkleScale: 0.38,
          motionScale: 0.48,
          overlayAlpha: 0.050,
          accentA: TruLuraTokens.auraCyan,
          accentB: TruLuraBrandColors.neonBlue,
          lightBegin: const Alignment(-0.2, -1),
          lightEnd: const Alignment(0.2, 1),
        );
      case TruLuraMode.trending:
        return _AtmospherePersonality(
          mistScale: 1.10,
          bokehScale: 1.05,
          sparkleScale: 1.18,
          motionScale: 1.04,
          overlayAlpha: 0.082,
          accentA: TruLuraBrandColors.glowGold,
          accentB: TruLuraTokens.auraPink,
          lightBegin: const Alignment(-1, -0.7),
          lightEnd: const Alignment(1, 0.85),
        );
      case TruLuraMode.aura:
        return _AtmospherePersonality(
          mistScale: 0.94,
          bokehScale: 0.88,
          sparkleScale: 0.86,
          motionScale: 0.90,
          overlayAlpha: 0.066,
          accentA: TruLuraTokens.auraPink,
          accentB: TruLuraTokens.auraCyan,
          lightBegin: const Alignment(-0.75, -1),
          lightEnd: const Alignment(0.75, 1),
        );
      case TruLuraMode.social:
        return _AtmospherePersonality(
          mistScale: 0.90,
          bokehScale: 0.82,
          sparkleScale: 0.82,
          motionScale: 0.84,
          overlayAlpha: 0.058,
          accentA: toneA,
          accentB: toneB,
          lightBegin: const Alignment(-0.9, -0.7),
          lightEnd: const Alignment(0.9, 0.9),
        );
    }
  }
}

/// Subtle animated aura layer used by the main shell.
///
/// It adds slow mood-reactive drift without forcing every screen to share the
/// same static wash. The painter is intentionally cheap: a few radial blobs and
/// tiny sparkles, all behind content.
class TruLuraAtmosphereLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final bool enabled;
  final double intensity;

  const TruLuraAtmosphereLayer({
    super.key,
    required this.tone,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraAtmosphereLayer> createState() => _TruLuraAtmosphereLayerState();
}

class _TruLuraAtmosphereLayerState extends State<TruLuraAtmosphereLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (a, b) = widget.tone.resolve(cs);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          return CustomPaint(
            painter: _AtmospherePainter(
              progress: _drift.value,
              tone: widget.tone,
              accentA: a,
              accentB: b,
              intensity: widget.intensity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class TruLuraEmotionalWeatherLayer extends StatefulWidget {
  final TruLuraModeTone tone;
  final bool enabled;
  final double intensity;

  const TruLuraEmotionalWeatherLayer({
    super.key,
    required this.tone,
    this.enabled = true,
    this.intensity = 1.0,
  });

  @override
  State<TruLuraEmotionalWeatherLayer> createState() =>
      _TruLuraEmotionalWeatherLayerState();
}

class _TruLuraEmotionalWeatherLayerState
    extends State<TruLuraEmotionalWeatherLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 44),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (a, b) = widget.tone.resolve(cs);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _EmotionalWeatherPainter(
              progress: _controller.value,
              tone: widget.tone,
              accentA: a,
              accentB: b,
              intensity: widget.intensity.clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _EmotionalWeatherPainter extends CustomPainter {
  final double progress;
  final TruLuraModeTone tone;
  final Color accentA;
  final Color accentB;
  final double intensity;

  const _EmotionalWeatherPainter({
    required this.progress,
    required this.tone,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = progress * math.pi * 2;
    final breathe = 0.5 + math.sin(phase) * 0.5;
    final drift = math.sin(phase * 0.47);
    final lift = switch (tone) {
      TruLuraModeTone.sync => 1.12,
      TruLuraModeTone.explore => 1.20,
      TruLuraModeTone.profile => 1.06,
      TruLuraModeTone.notifications => 1.02,
      TruLuraModeTone.messages => 0.94,
      TruLuraModeTone.aura => 1.0,
    };

    final fogPaint = Paint()
      ..blendMode = BlendMode.screen
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);

    void veil({
      required Offset from,
      required Offset to,
      required Color color,
      required double alpha,
      required double width,
    }) {
      fogPaint
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            color.withValues(alpha: alpha * intensity * lift),
            Colors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Offset.zero & size)
        ..strokeWidth = width
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(
          size.width * (0.22 + 0.05 * drift),
          size.height * (0.18 + 0.08 * breathe),
          size.width * (0.72 - 0.04 * drift),
          size.height * (0.62 - 0.05 * breathe),
          to.dx,
          to.dy,
        );
      canvas.drawPath(path, fogPaint);
    }

    veil(
      from: Offset(-size.width * 0.08, size.height * (0.28 + 0.04 * drift)),
      to: Offset(size.width * 1.08, size.height * (0.50 + 0.04 * breathe)),
      color: accentA,
      alpha: 0.055,
      width: size.shortestSide * 0.24,
    );
    veil(
      from: Offset(size.width * 1.04, size.height * (0.08 + 0.03 * breathe)),
      to: Offset(-size.width * 0.10, size.height * (0.84 - 0.03 * drift)),
      color: accentB,
      alpha: 0.045,
      width: size.shortestSide * 0.20,
    );

    final shimmerPaint = Paint()
      ..blendMode = BlendMode.screen
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(127 + tone.index);
    for (var i = 0; i < 9; i++) {
      final x = ((rng.nextDouble() + progress * (0.012 + i * 0.001)) % 1.0) *
          size.width;
      final y = rng.nextDouble() * size.height;
      final alpha = (0.014 + 0.010 * math.sin(phase + i).abs()) * intensity;
      shimmerPaint
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 0.7 + rng.nextDouble() * 0.7;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 18 + rng.nextDouble() * 22, y + 4 * drift),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionalWeatherPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tone != tone ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

class _AtmospherePainter extends CustomPainter {
  final double progress;
  final TruLuraModeTone tone;
  final Color accentA;
  final Color accentB;
  final double intensity;

  _AtmospherePainter({
    required this.progress,
    required this.tone,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = Curves.easeInOut.transform(progress);
    final glowPaint = Paint()..blendMode = BlendMode.screen;

    void aura(Offset center, double radius, Color color, double alpha) {
      glowPaint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * intensity),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, glowPaint);
    }

    final toneLift = switch (tone) {
      TruLuraModeTone.sync => 1.22,
      TruLuraModeTone.explore => 1.15,
      TruLuraModeTone.profile => 1.12,
      TruLuraModeTone.notifications => 1.02,
      TruLuraModeTone.messages => 0.96,
      TruLuraModeTone.aura => 1.0,
    };

    aura(
      Offset(size.width * (-0.10 + 0.18 * p), size.height * 0.16),
      size.shortestSide * 0.72,
      accentA,
      0.13 * toneLift,
    );
    aura(
      Offset(size.width * (1.06 - 0.14 * p), size.height * (0.42 + 0.08 * p)),
      size.shortestSide * 0.68,
      accentB,
      0.115 * toneLift,
    );
    aura(
      Offset(size.width * (0.42 + 0.08 * p), size.height * 1.05),
      size.shortestSide * 0.82,
      Color.lerp(accentA, accentB, 0.5) ?? accentA,
      0.08 * toneLift,
    );

    final sparklePaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.screen;
    final rnd = math.Random(81 + tone.index);
    final sparkleCount = switch (tone) {
      TruLuraModeTone.explore => 18,
      TruLuraModeTone.notifications => 14,
      TruLuraModeTone.sync => 12,
      _ => 10,
    };

    for (var i = 0; i < sparkleCount; i++) {
      final phase = (p + i * 0.137) % 1.0;
      final dx = rnd.nextDouble() * size.width;
      final dy = (rnd.nextDouble() * size.height + phase * 18) % size.height;
      final pulse = 0.55 + 0.45 * math.sin((phase + i) * math.pi * 2).abs();
      sparklePaint.color = Colors.white.withValues(
        alpha: 0.035 * pulse * intensity,
      );
      canvas.drawCircle(
          Offset(dx, dy), 0.8 + rnd.nextDouble() * 1.2, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tone != tone ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

class _FilmGrainPainter extends CustomPainter {
  final int seed;

  _FilmGrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (size.longestSide * 0.30).clamp(220, 520).round();
    for (var i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 0.8 + 0.15;
      // Locked: 3–6% subtle noise.
      final a = 0.016 + rnd.nextDouble() * 0.030;
      paint.color =
          (rnd.nextBool() ? Colors.white : Colors.black).withValues(alpha: a);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// New cinematic nebula mist layer (screen blend + radial gradients).
///
/// Kept separate from mode tone logic on purpose: this is a *global* subtle atmosphere.
class _CinematicNebulaMistLayer extends StatelessWidget {
  const _CinematicNebulaMistLayer();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness != Brightness.dark) return const SizedBox.shrink();
    return const IgnorePointer(
      child: CustomPaint(
        painter: _CinematicNebulaPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _CinematicNebulaPainter extends CustomPainter {
  const _CinematicNebulaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..blendMode = BlendMode.screen;

    void blob(Offset c, double r, Color col) {
      paint.shader = RadialGradient(
        colors: [col.withValues(alpha: 0.25), col.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    blob(Offset(size.width * 0.2, size.height * 0.2), size.width * 0.55,
        TruLuraTokens.auraViolet);
    blob(Offset(size.width * 0.85, size.height * 0.35), size.width * 0.45,
        TruLuraTokens.auraPink);
    blob(Offset(size.width * 0.55, size.height * 0.85), size.width * 0.60,
        TruLuraTokens.auraCyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CinematicBokehLayer extends StatelessWidget {
  const _CinematicBokehLayer();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness != Brightness.dark) return const SizedBox.shrink();
    return const IgnorePointer(
      child: Opacity(
        opacity: 0.22,
        child: CustomPaint(
          painter: _CinematicBokehPainter(seed: 7),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CinematicBokehPainter extends CustomPainter {
  final int seed;
  const _CinematicBokehPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rng = math.Random(seed);
    final paint = Paint()..blendMode = BlendMode.screen;

    for (int i = 0; i < 10; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = (18 + rng.nextDouble() * 70);

      final col = <Color>[
        TruLuraTokens.auraViolet,
        TruLuraTokens.auraPink,
        TruLuraTokens.auraCyan
      ][rng.nextInt(3)];

      paint.shader = RadialGradient(
        colors: [col.withValues(alpha: 0.35), col.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: r));

      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarDustLayer extends StatelessWidget {
  final TruLuraModeTone tone;
  final bool datingOnly;
  final double opacity;

  const _StarDustLayer(
      {required this.tone, required this.datingOnly, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness != Brightness.dark) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final (a, b) = tone.resolve(cs);
    final accentBoost = switch (tone) {
      TruLuraModeTone.sync => 1.25,
      TruLuraModeTone.explore => 1.08,
      TruLuraModeTone.messages => 0.92,
      TruLuraModeTone.notifications => 1.02,
      TruLuraModeTone.profile => 1.12,
      TruLuraModeTone.aura => 0.95,
    };

    final romanticA = const Color(0xFFFF6BD6);
    final romanticB = const Color(0xFF8F5CFF);

    return IgnorePointer(
      child: CustomPaint(
        painter: _StarDustPainter(
          starColor: Colors.white.withValues(alpha: opacity),
          accentA: (datingOnly ? romanticA : a)
              .withValues(alpha: opacity * 0.55 * accentBoost),
          accentB: (datingOnly ? romanticB : b)
              .withValues(alpha: opacity * 0.48 * accentBoost),
        ),
      ),
    );
  }
}

class _StarDustPainter extends CustomPainter {
  final Color starColor;
  final Color accentA;
  final Color accentB;

  _StarDustPainter(
      {required this.starColor, required this.accentA, required this.accentB});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rnd = math.Random(42);
    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Fine “stardust” specks.
    // Slightly denser to match reference (still respects [opacity] cap).
    final count = (size.shortestSide * 0.34).clamp(160, 320).round();
    for (var i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = (rnd.nextDouble() * 1.4) + 0.25;
      final alpha = (0.06 + rnd.nextDouble() * 0.20);

      dotPaint.color = starColor.withValues(alpha: starColor.a * alpha);
      canvas.drawCircle(Offset(dx, dy), r, dotPaint);
    }

    // A handful of brighter “hero” stars (tiny cross sparkles), very subtle.
    final heroCount = (size.shortestSide * 0.04).clamp(8, 18).round();
    final heroPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < heroCount; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final base = (1.6 + rnd.nextDouble() * 2.4);
      final a = starColor.a * (0.34 + rnd.nextDouble() * 0.24);
      heroPaint
        ..color = Colors.white.withValues(alpha: a)
        ..strokeWidth = 1.0 + rnd.nextDouble() * 0.6
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, base * 1.4);

      canvas.drawLine(Offset(dx - base, dy), Offset(dx + base, dy), heroPaint);
      canvas.drawLine(Offset(dx, dy - base), Offset(dx, dy + base), heroPaint);
    }

    // A few soft radial “light blooms” behind content.
    void bloom(Alignment center, double radius, Color color) {
      final rect = Rect.fromCircle(
        center: Offset(
            (center.x + 1) * size.width / 2, (center.y + 1) * size.height / 2),
        radius: radius,
      );
      final shader = RadialGradient(
        colors: [color, Colors.transparent],
        stops: const [0, 1],
      ).createShader(rect);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    }

    bloom(const Alignment(-0.65, -0.55), size.shortestSide * 0.75, accentA);
    bloom(const Alignment(0.70, -0.35), size.shortestSide * 0.65, accentB);
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter oldDelegate) {
    return oldDelegate.starColor != starColor ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB;
  }
}

class _TruLuraBokehLayer extends StatelessWidget {
  const _TruLuraBokehLayer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    Color tint(Color c, double a) => c.withValues(alpha: a);
    final baseA = brightness == Brightness.dark ? 0.26 : 0.18;

    return Stack(
      children: [
        Positioned(
          top: -90,
          left: -60,
          child: _GlowBlob(
              size: 260,
              colorA: tint(cs.primary, baseA),
              colorB: tint(cs.secondary, baseA * 0.85)),
        ),
        Positioned(
          top: 140,
          right: -80,
          child: _GlowBlob(
              size: 300,
              colorA: tint(cs.tertiary, baseA),
              colorB: tint(cs.primary, baseA * 0.75)),
        ),
        Positioned(
          bottom: -120,
          left: 30,
          child: _GlowBlob(
              size: 320,
              colorA: tint(cs.secondary, baseA * 0.95),
              colorB: tint(cs.tertiary, baseA * 0.70)),
        ),
        if (brightness == Brightness.dark)
          Positioned(
            bottom: 120,
            right: -110,
            child: _GlowBlob(
              size: 360,
              colorA:
                  TruLuraBrandColors.deepBlue.withValues(alpha: baseA * 0.85),
              colorB: tint(cs.primary, baseA * 0.70),
            ),
          ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color colorA;
  final Color colorB;

  const _GlowBlob(
      {required this.size, required this.colorA, required this.colorB});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [colorA, colorB.withValues(alpha: 0), Colors.transparent],
            stops: const [0, 0.55, 1],
          ),
        ),
      ),
    );
  }
}
