import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_empty_state_card.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';

const double kTruluraFeedMaxWidth = 760;
const double kTruluraDesktopContentMaxWidth = 1240;
const double kTruluraCompactContentMaxWidth = 900;
const double kTruluraBottomNavClearance = 112;

double truluraResponsiveContentMaxWidth(double viewportWidth) {
  if (viewportWidth >= 1180) return kTruluraDesktopContentMaxWidth;
  if (viewportWidth >= 900) return kTruluraCompactContentMaxWidth;
  return viewportWidth;
}

class TruluraFeedLane extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const TruluraFeedLane({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.maxWidth = kTruluraFeedMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class TruluraContentLane extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;

  const TruluraContentLane({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ??
        truluraResponsiveContentMaxWidth(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

class TruluraFeedSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TruluraFeedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class TruluraFeedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final TruLuraGlyph? icon;

  const TruluraFeedChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TruLuraGlowPill(
      label: label,
      selected: selected,
      onTap: onTap,
      icon: icon,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    );
  }
}

class TruluraGlowButton extends StatelessWidget {
  final String label;
  final TruLuraGlyph glyph;
  final VoidCallback? onPressed;

  const TruluraGlowButton({
    super.key,
    required this.label,
    required this.glyph,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: TruLuraIcon(
        glyph: glyph,
        size: 17,
        active: true,
        color: Colors.white,
      ),
      label: Text(label),
    );
  }
}

class TruluraProfileMiniCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? image;
  final int? compatibility;
  final VoidCallback? onTap;

  const TruluraProfileMiniCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.image,
    this.compatibility,
    this.onTap,
  });

  ImageProvider<Object>? _imageProviderFor(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    final isNetwork = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isNetwork ? NetworkImage(v) : AssetImage(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          TruLuraHaloAvatar(image: _imageProviderFor(image), radius: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          if (compatibility != null) ...[
            const SizedBox(width: 8),
            Text(
              '$compatibility%',
              style: t.labelMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }
}

class TruluraFeedEmptyState extends StatelessWidget {
  final TruLuraGlyph icon;
  final String title;
  final String message;
  final List<TruStateAction> actions;

  const TruluraFeedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const <TruStateAction>[],
  });

  @override
  Widget build(BuildContext context) {
    return TruluraEmptyStateCard(
      icon: icon,
      title: title,
      message: message,
      actions: actions,
    );
  }
}

enum TruluraFeedDemoCardKind {
  recommendation,
  quiz,
  supportPrompt,
  community,
  conversation,
}

class TruluraFeedDemoCard extends StatelessWidget {
  final TruluraFeedDemoCardKind kind;
  final String title;
  final String body;
  final List<String> chips;
  final String? actionLabel;
  final bool emphasized;
  final VoidCallback? onTap;

  const TruluraFeedDemoCard({
    super.key,
    required this.kind,
    required this.title,
    required this.body,
    this.chips = const <String>[],
    this.actionLabel,
    this.emphasized = false,
    this.onTap,
  });

  TruLuraGlyph get _glyph => switch (kind) {
        TruluraFeedDemoCardKind.recommendation => TruLuraGlyph.spark,
        TruluraFeedDemoCardKind.quiz => TruLuraGlyph.insights,
        TruluraFeedDemoCardKind.supportPrompt => TruLuraGlyph.moon,
        TruluraFeedDemoCardKind.community => TruLuraGlyph.explore,
        TruluraFeedDemoCardKind.conversation => TruLuraGlyph.messages,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final (accentA, accentB, label) = switch (kind) {
      TruluraFeedDemoCardKind.recommendation => (
          TruLuraTokens.auraViolet,
          TruLuraTokens.auraCyan,
          'Recommended'
        ),
      TruluraFeedDemoCardKind.quiz => (
          TruLuraBrandColors.glowGold,
          TruLuraTokens.auraViolet,
          'Quick tuning'
        ),
      TruluraFeedDemoCardKind.supportPrompt => (
          TruLuraTokens.auraCyan,
          TruLuraBrandColors.neonPurple,
          'Soft prompt'
        ),
      TruluraFeedDemoCardKind.community => (
          TruLuraTokens.auraCyan,
          TruLuraTokens.auraPink,
          'Community'
        ),
      TruluraFeedDemoCardKind.conversation => (
          TruLuraTokens.auraPink,
          TruLuraTokens.auraViolet,
          'Starter'
        ),
    };
    final accent = (emphasized ? accentA : accentB).withValues(alpha: 0.08);

    return TruLuraGlassCard(
      radius: 24,
      tint: accent,
      depth: true,
      glow: accentB,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DemoCardWeatherPainter(
                  accentA: accentA,
                  accentB: accentB,
                  emphasized: emphasized,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentA.withValues(alpha: 0.72),
                          accentB.withValues(alpha: 0.34),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: TruLuraEffects.multiAuraGlow(
                        accentA,
                        accentB,
                        intensity: emphasized ? 0.50 : 0.30,
                      ),
                    ),
                    child: TruLuraIcon(
                      glyph: _glyph,
                      size: 18,
                      active: true,
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: t.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: t.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  if (emphasized)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: accentB.withValues(alpha: 0.12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: TruLuraSurfaces.hairline,
                        ),
                      ),
                      child: Text(
                        'Tuned',
                        style: t.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface.withValues(alpha: 0.86),
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 11),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentA.withValues(alpha: 0.08),
                      cs.surfaceContainerHighest.withValues(alpha: 0.12),
                      accentB.withValues(alpha: 0.07),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: Text(
                  body,
                  style: t.bodySmall?.copyWith(
                    color: TruLuraTokens.textSecondary,
                    height: 1.34,
                  ),
                ),
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final chip in chips.take(4))
                      TruluraFeedChip(label: chip, selected: emphasized),
                  ],
                ),
              ],
              if (actionLabel != null && onTap != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: onTap,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoCardWeatherPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final bool emphasized;

  const _DemoCardWeatherPainter({
    required this.accentA,
    required this.accentB,
    required this.emphasized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: const Alignment(0.82, -0.62),
        radius: 1.0,
        colors: [
          accentA.withValues(alpha: emphasized ? 0.13 : 0.075),
          accentB.withValues(alpha: emphasized ? 0.075 : 0.040),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withValues(alpha: emphasized ? 0.055 : 0.032);
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.74)
      ..cubicTo(size.width * 0.28, size.height * 0.58, size.width * 0.62,
          size.height * 0.86, size.width * 0.96, size.height * 0.64);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _DemoCardWeatherPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.emphasized != emphasized;
  }
}
