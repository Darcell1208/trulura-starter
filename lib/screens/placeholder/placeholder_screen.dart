import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_world_layers.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PlaceholderScreen({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = (subtitle ?? 'This world is being prepared for you.')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final summary =
        lines.isEmpty ? 'This world is being prepared for you.' : lines.first;
    final details = lines.length > 1 ? lines.sublist(1) : const <String>[];
    final lowerTitle = title.toLowerCase();
    final isLuxe = lowerTitle.contains('luxe');
    final isJourney = lowerTitle.contains('journey');
    final worldMode = isLuxe
        ? TruLuraMode.sync
        : isJourney
            ? TruLuraMode.vent
            : TruLuraMode.trending;
    final worldTone = isLuxe
        ? TruLuraModeTone.profile
        : isJourney
            ? TruLuraModeTone.aura
            : TruLuraModeTone.explore;
    final primary = isLuxe
        ? TruLuraBrandColors.glowGold
        : isJourney
            ? TruLuraTokens.auraCyan
            : TruLuraTokens.auraViolet;
    final secondary =
        isLuxe ? TruLuraTokens.auraPink : TruLuraBrandColors.glowGold;

    if (isJourney) {
      return _TruJourneyTimelineDestination(
        title: title,
        summary: summary,
        details: details,
        primary: primary,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => TruNavigation.goBackOrReturn(context),
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const TruLuraIcon(glyph: TruLuraGlyph.close, size: 20),
            onPressed: () => TruNavigation.closeModule(context),
          ),
        ],
      ),
      body: TruLuraLayeredBackground(
        tone: worldTone,
        mode: worldMode,
        modeAccent: primary.withValues(alpha: 0.14),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            TruWorldStage(
              overline: 'TruLura destination',
              title: '$title is opening as an emotional world.',
              subtitle:
                  '$summary TruLura keeps the atmosphere, safety, and return path alive while deeper live systems connect behind the scenes.',
              glyph: isLuxe
                  ? TruLuraGlyph.star
                  : isJourney
                      ? TruLuraGlyph.insights
                      : TruLuraGlyph.spark,
              primary: primary,
              secondary: secondary,
              focalLabel: 'World signal',
              focalValue: 'Live',
              guidance: [
                TruWorldAction(
                  label: 'Return to Aura',
                  glyph: TruLuraGlyph.aura,
                  primary: true,
                  accent: primary,
                  onTap: () => TruNavigation.goHome(context),
                ),
                TruWorldAction(
                  label: 'Close Layer',
                  glyph: TruLuraGlyph.close,
                  accent: cs.onSurface.withValues(alpha: 0.78),
                  onTap: () => TruNavigation.closeModule(context),
                ),
              ],
              portals: const [
                TruRealmPortal(
                  title: 'Emotional Context',
                  subtitle: 'Your return path stays intact.',
                  glyph: TruLuraGlyph.shield,
                  accent: TruLuraTokens.auraCyan,
                ),
                TruRealmPortal(
                  title: 'World Preserved',
                  subtitle: 'The world stays cinematic and calm.',
                  glyph: TruLuraGlyph.aura,
                  accent: TruLuraTokens.auraViolet,
                ),
                TruRealmPortal(
                  title: 'Next Layer',
                  subtitle: 'Live content can enter without resets.',
                  glyph: TruLuraGlyph.insights,
                  accent: TruLuraBrandColors.glowGold,
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final line in details)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: cs.surface.withValues(alpha: 0.18),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TruJourneyTimelineDestination extends StatelessWidget {
  final String title;
  final String summary;
  final List<String> details;
  final Color primary;

  const _TruJourneyTimelineDestination({
    required this.title,
    required this.summary,
    required this.details,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => TruNavigation.goBackOrReturn(context),
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const TruLuraIcon(glyph: TruLuraGlyph.close, size: 20),
            onPressed: () => TruNavigation.closeModule(context),
          ),
        ],
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.vent,
        modeAccent: primary.withValues(alpha: 0.14),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                constraints: const BoxConstraints(minHeight: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.20),
                    width: TruLuraSurfaces.hairline,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.12),
                      cs.surface.withValues(alpha: 0.24),
                      TruLuraTokens.ink.withValues(alpha: 0.58),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _JourneyTimelinePainter(primary: primary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 680;
                          final intro = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EMOTIONAL EVOLUTION',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your journey unfolds over time.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: TruLuraTokens.textPrimary,
                                      fontFamily: 'Georgia',
                                      height: 1.04,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$summary TruJourney tracks progression, emotional evolution, and the story of who you are becoming.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: TruLuraTokens.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _JourneyPill(
                                    label: 'Return to Aura',
                                    glyph: TruLuraGlyph.aura,
                                    primary: true,
                                    onTap: () => TruNavigation.goHome(context),
                                  ),
                                  _JourneyPill(
                                    label: 'Close Layer',
                                    glyph: TruLuraGlyph.close,
                                    onTap: () =>
                                        TruNavigation.closeModule(context),
                                  ),
                                ],
                              ),
                            ],
                          );
                          const timeline = _JourneyMilestoneRail();
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                intro,
                                const SizedBox(height: 24),
                                timeline,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(flex: 5, child: intro),
                              const SizedBox(width: 28),
                              const Expanded(flex: 4, child: timeline),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final line in details)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cs.surface.withValues(alpha: 0.18),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JourneyMilestoneRail extends StatelessWidget {
  const _JourneyMilestoneRail();

  @override
  Widget build(BuildContext context) {
    const milestones = [
      ('Begin', 'First signals, intentions, and emotional baseline.'),
      ('Notice', 'Patterns become visible through reflection.'),
      ('Practice', 'New rhythms form through repeated choices.'),
      ('Evolve', 'Your emotional story gains direction.'),
    ];
    return Column(
      children: [
        for (var i = 0; i < milestones.length; i++) ...[
          _JourneyMilestone(
            index: i + 1,
            title: milestones[i].$1,
            body: milestones[i].$2,
            active: i <= 1,
          ),
          if (i != milestones.length - 1)
            Container(
              width: 2,
              height: 18,
              color: TruLuraTokens.auraCyan.withValues(alpha: 0.22),
            ),
        ],
      ],
    );
  }
}

class _JourneyMilestone extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  final bool active;

  const _JourneyMilestone({
    required this.index,
    required this.title,
    required this.body,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        active ? TruLuraTokens.auraCyan : TruLuraTokens.textSecondary;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: active ? 0.075 : 0.040),
        border: Border.all(
          color: accent.withValues(alpha: active ? 0.28 : 0.12),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: active ? 0.18 : 0.08),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
            ),
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: TruLuraTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TruLuraTokens.textSecondary,
                        height: 1.28,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPill extends StatelessWidget {
  final String label;
  final TruLuraGlyph glyph;
  final VoidCallback onTap;
  final bool primary;

  const _JourneyPill({
    required this.label,
    required this.glyph,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        primary ? TruLuraTokens.auraCyan : TruLuraBrandColors.glowGold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: accent.withValues(alpha: primary ? 0.20 : 0.10),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TruLuraIcon(glyph: glyph, size: 17, active: primary, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TruLuraTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyTimelinePainter extends CustomPainter {
  final Color primary;

  const _JourneyTimelinePainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withValues(alpha: 0.12),
          Colors.transparent,
          TruLuraBrandColors.glowGold.withValues(alpha: 0.07),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1
      ..color = primary.withValues(alpha: 0.18);
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.82)
      ..cubicTo(size.width * 0.26, size.height * 0.64, size.width * 0.36,
          size.height * 0.42, size.width * 0.52, size.height * 0.54)
      ..cubicTo(size.width * 0.70, size.height * 0.68, size.width * 0.76,
          size.height * 0.28, size.width * 0.90, size.height * 0.18);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _JourneyTimelinePainter oldDelegate) {
    return oldDelegate.primary != primary;
  }
}
