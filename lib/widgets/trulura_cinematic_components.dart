import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_brand_logo.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class TruLuraLogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool centered;

  const TruLuraLogoHeader({
    super.key,
    this.title = 'TRULURA',
    this.subtitle = 'LIVE YOUR TRUTH. CONNECT YOUR SOUL.',
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        const TruLuraBrandLogo(size: 62, radius: 22),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: TruLuraTokens.textPrimary,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
                letterSpacing: 9,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TruLuraTokens.textSecondary.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.9,
              ),
        ),
      ],
    );
  }
}

class CosmicGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;
  final double opacity;

  const CosmicGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.accent,
    this.opacity = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final glow = accent ?? TruLuraTokens.auraViolet;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: soft ? 8 : 22,
          sigmaY: soft ? 8 : 22,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: soft ? 0.060 : opacity),
                TruLuraTokens.deepIndigo.withValues(alpha: 0.36),
                glow.withValues(alpha: soft ? 0.035 : 0.085),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: soft ? 0.11 : 0.15),
              width: TruLuraSurfaces.hairline,
            ),
            boxShadow: soft
                ? const <BoxShadow>[]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 38,
                      spreadRadius: -18,
                      offset: const Offset(0, 24),
                    ),
                    BoxShadow(
                      color: glow.withValues(alpha: 0.18 * app.glowScale),
                      blurRadius: 48,
                      spreadRadius: -24,
                      offset: const Offset(0, 18),
                    ),
                  ],
          ),
          child: CustomPaint(
            painter: _CosmicGlassPainter(glow: glow, enabled: !soft),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class AuraRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color accentA;
  final Color accentB;
  final Widget? fallback;

  const AuraRingAvatar({
    super.key,
    this.imageUrl,
    this.size = 86,
    this.accentA = TruLuraTokens.auraViolet,
    this.accentB = TruLuraTokens.auraPink,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final soft = context.watch<AppProvider>().softModeEnabled;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AuraRingPainter(
          accentA: accentA,
          accentB: accentB,
          soft: soft,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.105),
          child: ClipOval(
            child: (imageUrl ?? '').isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback ?? _avatarFallback(),
                  )
                : fallback ?? _avatarFallback(),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentA.withValues(alpha: 0.75),
            accentB.withValues(alpha: 0.55),
            TruLuraTokens.ink,
          ],
        ),
      ),
      child: const Center(
        child: TruLuraIcon(
          glyph: TruLuraGlyph.person,
          active: true,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}

class EmotionalChip extends StatelessWidget {
  final String label;
  final TruLuraGlyph? glyph;
  final Color accent;
  final bool selected;
  final VoidCallback? onTap;

  const EmotionalChip({
    super.key,
    required this.label,
    this.glyph,
    this.accent = TruLuraTokens.auraViolet,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: app.motionDuration,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    accent.withValues(alpha: soft ? 0.25 : 0.42),
                    TruLuraTokens.auraPink
                        .withValues(alpha: soft ? 0.12 : 0.24),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.070),
                    Colors.white.withValues(alpha: 0.035),
                  ],
                ),
          border: Border.all(
            color: (selected ? accent : Colors.white)
                .withValues(alpha: selected ? 0.42 : 0.12),
            width: TruLuraSurfaces.hairline,
          ),
          boxShadow: selected && !soft
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22 * app.glowScale),
                    blurRadius: 20,
                    spreadRadius: -8,
                  )
                ]
              : const <BoxShadow>[],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              TruLuraIcon(
                  glyph: glyph!, size: 15, active: selected, color: accent),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? TruLuraTokens.textPrimary
                        : TruLuraTokens.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlowIconButton extends StatelessWidget {
  final TruLuraGlyph glyph;
  final VoidCallback onTap;
  final String? tooltip;
  final Color accent;

  const GlowIconButton({
    super.key,
    required this.glyph,
    required this.onTap,
    this.tooltip,
    this.accent = TruLuraTokens.auraViolet,
  });

  @override
  Widget build(BuildContext context) {
    final soft = context.watch<AppProvider>().softModeEnabled;
    final child = InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: soft ? 0.18 : 0.32),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: TruLuraSurfaces.hairline,
          ),
          boxShadow: soft
              ? const <BoxShadow>[]
              : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.20),
                    blurRadius: 24,
                    spreadRadius: -10,
                  ),
                ],
        ),
        child: TruLuraIcon(glyph: glyph, active: true, size: 19),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class CinematicSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const CinematicSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TruLuraTokens.textPrimary,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TruLuraTokens.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ImmersiveWorldHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color accentA;
  final Color accentB;
  final List<Widget> actions;
  final List<Widget> signals;
  final String focalLabel;
  final double minHeight;

  const ImmersiveWorldHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.glyph,
    this.accentA = TruLuraTokens.auraViolet,
    this.accentB = TruLuraTokens.auraPink,
    this.actions = const <Widget>[],
    this.signals = const <Widget>[],
    this.focalLabel = 'Aura pulse',
    this.minHeight = 280,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    return CosmicGlassCard(
      radius: 36,
      accent: accentA,
      opacity: soft ? 0.070 : 0.12,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WorldHeroPainter(
                    accentA: accentA,
                    accentB: accentB,
                    soft: soft,
                  ),
                ),
              ),
              Positioned(
                right: -26,
                top: 18,
                bottom: -22,
                width: 290,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _WorldHeroFocalPainter(
                      accentA: accentA,
                      accentB: accentB,
                      soft: soft,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final text = _WorldHeroText(
                      eyebrow: eyebrow,
                      title: title,
                      subtitle: subtitle,
                      glyph: glyph,
                      accent: accentA,
                      actions: actions,
                      signals: signals,
                    );
                    final focal = _WorldHeroFocal(
                      glyph: glyph,
                      label: focalLabel,
                      accentA: accentA,
                      accentB: accentB,
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text,
                          const SizedBox(height: 18),
                          Align(alignment: Alignment.center, child: focal),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 6, child: text),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: focal),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldHeroText extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color accent;
  final List<Widget> actions;
  final List<Widget> signals;

  const _WorldHeroText({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.accent,
    required this.actions,
    required this.signals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlowIconButton(glyph: glyph, onTap: () {}, accent: accent),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: TruLuraTokens.textPrimary,
                fontFamily: 'Georgia',
                height: 1.04,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TruLuraTokens.textSecondary,
                  height: 1.45,
                ),
          ),
        ),
        if (signals.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: signals),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ],
    );
  }
}

class _WorldHeroFocal extends StatelessWidget {
  final TruLuraGlyph glyph;
  final String label;
  final Color accentA;
  final Color accentB;

  const _WorldHeroFocal({
    required this.glyph,
    required this.label,
    required this.accentA,
    required this.accentB,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AuraRingAvatar(
            size: 168,
            accentA: accentA,
            accentB: accentB,
            fallback: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentA.withValues(alpha: 0.38),
                    accentB.withValues(alpha: 0.22),
                    TruLuraTokens.ink,
                  ],
                ),
              ),
              child: Center(
                child: TruLuraIcon(
                  glyph: glyph,
                  active: true,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: EmotionalChip(
              label: label,
              glyph: glyph,
              selected: true,
              accent: accentA,
            ),
          ),
        ],
      ),
    );
  }
}

class ImmersiveSideRail extends StatelessWidget {
  final List<Widget> children;

  const ImmersiveSideRail({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return CosmicGlassCard(
      radius: 28,
      padding: const EdgeInsets.all(12),
      accent: TruLuraTokens.auraViolet,
      child: Column(children: children),
    );
  }
}

class AuraFeedCard extends StatelessWidget {
  final String title;
  final String body;
  final String meta;
  final TruLuraGlyph glyph;
  final Color accent;

  const AuraFeedCard({
    super.key,
    required this.title,
    required this.body,
    required this.meta,
    this.glyph = TruLuraGlyph.aura,
    this.accent = TruLuraTokens.auraViolet,
  });

  @override
  Widget build(BuildContext context) {
    return CosmicGlassCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AuraRingAvatar(
                  size: 52, accentA: accent, accentB: TruLuraTokens.auraPink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: TruLuraTokens.textPrimary,
                                  fontWeight: FontWeight.w900,
                                )),
                    Text(meta,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: TruLuraTokens.textMuted,
                              fontWeight: FontWeight.w800,
                            )),
                  ],
                ),
              ),
              TruLuraIcon(glyph: glyph, active: true, color: accent),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TruLuraTokens.textPrimary,
                  fontFamily: 'Georgia',
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EmotionalChip(
                  label: 'Glow',
                  glyph: TruLuraGlyph.heartOutline,
                  accent: accent),
              EmotionalChip(
                  label: 'Relate',
                  glyph: TruLuraGlyph.messages,
                  accent: TruLuraTokens.auraCyan),
              EmotionalChip(
                  label: 'Save',
                  glyph: TruLuraGlyph.bookmark,
                  accent: TruLuraBrandColors.glowGold),
            ],
          ),
        ],
      ),
    );
  }
}

class WorldCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color accent;
  final VoidCallback? onTap;

  const WorldCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.glyph = TruLuraGlyph.explore,
    this.accent = TruLuraTokens.auraCyan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: CosmicGlassCard(
        radius: 24,
        accent: accent,
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlowIconButton(
                  glyph: glyph, onTap: onTap ?? () {}, accent: accent),
              const SizedBox(height: 26),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: TruLuraTokens.textPrimary,
                        fontFamily: 'Georgia',
                      )),
              const SizedBox(height: 6),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TruLuraTokens.textSecondary,
                        height: 1.3,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncMatchCard extends StatelessWidget {
  final String name;
  final int score;
  final VoidCallback? onSpark;

  const SyncMatchCard({
    super.key,
    required this.name,
    this.score = 88,
    this.onSpark,
  });

  @override
  Widget build(BuildContext context) {
    return CosmicGlassCard(
      accent: TruLuraBrandColors.glowGold,
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AuraRingAvatar(
                size: 88,
                accentA: TruLuraBrandColors.glowGold,
                accentB: TruLuraTokens.auraPink,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: TruLuraTokens.textPrimary,
                                  fontFamily: 'Georgia',
                                )),
                    const SizedBox(height: 5),
                    const Text(
                      'Soul-aligned connection',
                      style: TextStyle(color: TruLuraTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              _ScoreRing(score: score),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              EmotionalChip(
                  label: 'Deep conversations', accent: TruLuraTokens.auraCyan),
              EmotionalChip(label: 'Slow burn', accent: TruLuraTokens.auraPink),
              EmotionalChip(
                  label: 'Shared values', accent: TruLuraBrandColors.glowGold),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: EmotionalChip(
                  label: 'Pass Softly',
                  glyph: TruLuraGlyph.back,
                  accent: TruLuraTokens.auraCyan,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EmotionalChip(
                  label: 'Spark',
                  glyph: TruLuraGlyph.spark,
                  selected: true,
                  accent: TruLuraBrandColors.glowGold,
                  onTap: onSpark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileHeroCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? imageUrl;

  const ProfileHeroCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CosmicGlassCard(
      radius: 34,
      accent: TruLuraTokens.auraPink,
      child: Row(
        children: [
          AuraRingAvatar(imageUrl: imageUrl, size: 96),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: TruLuraTokens.textPrimary,
                          fontFamily: 'Georgia',
                        )),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TruLuraTokens.textSecondary,
                          height: 1.35,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;

  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _ScoreRingPainter(progress: score / 100),
        child: Center(
          child: Text(
            '$score%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TruLuraTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _CosmicGlassPainter extends CustomPainter {
  final Color glow;
  final bool enabled;

  const _CosmicGlassPainter({required this.glow, required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: const Alignment(-0.85, -0.95),
        radius: 1.25,
        colors: [
          Colors.white.withValues(alpha: 0.055),
          glow.withValues(alpha: 0.070),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final star = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 9; i++) {
      final x = (math.sin(i * 12.91) * 0.5 + 0.5) * size.width;
      final y = (math.cos(i * 8.27) * 0.5 + 0.5) * size.height;
      canvas.drawCircle(Offset(x, y), i.isEven ? 0.9 : 0.55, star);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicGlassPainter oldDelegate) {
    return oldDelegate.glow != glow || oldDelegate.enabled != enabled;
  }
}

class _WorldHeroPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final bool soft;

  const _WorldHeroPainter({
    required this.accentA,
    required this.accentB,
    required this.soft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TruLuraTokens.ink.withValues(alpha: 0.92),
          TruLuraTokens.deepIndigo.withValues(alpha: 0.74),
          accentA.withValues(alpha: soft ? 0.10 : 0.22),
          accentB.withValues(alpha: soft ? 0.06 : 0.16),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final horizon = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentB.withValues(alpha: soft ? 0.08 : 0.24),
          TruLuraBrandColors.glowGold.withValues(alpha: soft ? 0.05 : 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.54, size.width, 80));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.54, size.width, 80),
      horizon,
    );

    final star = Paint()
      ..color = Colors.white.withValues(alpha: soft ? 0.10 : 0.26);
    for (var i = 0; i < (soft ? 20 : 54); i++) {
      final x = ((math.sin(i * 31.7) + 1) / 2) * size.width;
      final y = ((math.cos(i * 19.3) + 1) / 2) * size.height * 0.72;
      canvas.drawCircle(Offset(x, y), i % 8 == 0 ? 1.1 : 0.55, star);
    }

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = soft ? 0.8 : 1.15
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: soft ? 0.16 : 0.36),
          accentB.withValues(alpha: soft ? 0.12 : 0.30),
          Colors.transparent,
        ],
      ).createShader(rect);
    for (var i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(-20, size.height * (0.42 + i * 0.10))
        ..cubicTo(
          size.width * 0.26,
          size.height * (0.28 - i * 0.04),
          size.width * 0.58,
          size.height * (0.70 + i * 0.03),
          size.width + 30,
          size.height * (0.36 + i * 0.05),
        );
      canvas.drawPath(path, orbit);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldHeroPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.soft != soft;
  }
}

class _WorldHeroFocalPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final bool soft;

  const _WorldHeroFocalPainter({
    required this.accentA,
    required this.accentB,
    required this.soft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.45);
    final maxRadius = size.shortestSide * 0.44;
    for (var i = 0; i < 5; i++) {
      final radius = maxRadius * (0.42 + i * 0.14);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2.4 : 1.0
        ..shader = SweepGradient(
          colors: [
            accentA.withValues(alpha: soft ? 0.16 : 0.42),
            accentB.withValues(alpha: soft ? 0.12 : 0.34),
            TruLuraBrandColors.glowGold.withValues(alpha: soft ? 0.08 : 0.26),
            accentA.withValues(alpha: soft ? 0.16 : 0.42),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }

    if (!soft) {
      final glow = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            accentB.withValues(alpha: 0.22),
            accentA.withValues(alpha: 0.11),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
      canvas.drawCircle(center, maxRadius, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldHeroFocalPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.soft != soft;
  }
}

class _AuraRingPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final bool soft;

  const _AuraRingPainter({
    required this.accentA,
    required this.accentB,
    required this.soft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = soft ? 3 : 4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [accentA, accentB, TruLuraBrandColors.glowGold, accentA],
      ).createShader(rect);
    canvas.drawCircle(center, radius, stroke);

    if (!soft) {
      final halo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = accentB.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, radius - 1, halo);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraRingPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.soft != soft;
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;

  const _ScoreRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawCircle(center, radius, base);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          TruLuraTokens.auraPink,
          TruLuraBrandColors.glowGold,
          TruLuraTokens.auraCyan,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
