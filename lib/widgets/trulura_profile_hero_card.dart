import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/aura_avatar.dart';
import 'package:trulura/widgets/breathing_glow.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraProfileHeroCard.
class TruluraProfileHeroCard extends StatelessWidget {
  final String name;
  final String? handle;
  final String bio;
  final String avatarPath;
  final int auraStrength;
  final VoidCallback onOpenSettings;

  const TruluraProfileHeroCard({
    super.key,
    required this.name,
    required this.handle,
    required this.bio,
    required this.avatarPath,
    required this.auraStrength,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    final mood = (user?.moodTags.isNotEmpty ?? false)
        ? user!.moodTags.first
        : 'Reflective';
    final vibe = user?.vibeLabel.label ?? 'Old Soul';
    final intent =
        (user?.intents.isNotEmpty ?? false) ? user!.intents.first : 'Social';
    final identityAccent = _identityAccent(mood, intent);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 28,
            left: 0,
            right: 0,
            height: 260,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      identityAccent.withValues(alpha: 0.18),
                      TruLuraTokens.auraCyan.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HeroAuraFieldPainter(
                  accent: identityAccent,
                  secondary: TruLuraTokens.auraCyan,
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 2,
            child: _EnergyIndicator(
              label: mood,
              accent: identityAccent,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: onOpenSettings,
              icon: TruLuraIcon(
                  glyph: TruLuraGlyph.filter,
                  size: 20,
                  active: true,
                  color: cs.onSurface.withValues(alpha: 0.84)),
              tooltip: 'Settings',
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              BreathingGlow(
                enabled: !app.softModeEnabled,
                glowColor: identityAccent,
                maxBlur: 58,
                minBlur: 24,
                maxAlpha: 0.30,
                minAlpha: 0.10,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 148,
                      height: 148,
                      child: CustomPaint(
                        painter: _AvatarAuraRingPainter(
                          accent: identityAccent,
                          secondary: TruLuraTokens.auraCyan,
                        ),
                      ),
                    ),
                    AuraAvatar(
                      image: avatarPath,
                      compatibility: auraStrength,
                      size: 108,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              if ((handle ?? '').trim().isNotEmpty) ...[
                Text(
                  handle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
              ] else
                const SizedBox(height: 8),
              _AuraSignaturePill(strength: auraStrength),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _IdentityChip(
                    label: vibe,
                    glyph: TruLuraGlyph.spark,
                    accent: identityAccent,
                  ),
                  _IdentityChip(
                    label: intent,
                    glyph: TruLuraGlyph.aura,
                    accent: TruLuraTokens.auraCyan,
                  ),
                  _IdentityChip(
                    label: 'emotional weather',
                    glyph: TruLuraGlyph.moon,
                    accent: TruLuraBrandColors.glowGold,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _PresenceRhythmStrip(
                accent: identityAccent,
                mood: mood,
                intent: intent,
              ),
              const SizedBox(height: 10),
              Text(
                bio,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4, color: cs.onSurface.withValues(alpha: 0.80)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _identityAccent(String mood, String intent) {
    final key = '$mood $intent'.toLowerCase();
    if (key.contains('flirt') || key.contains('dating')) {
      return TruLuraTokens.auraPink;
    }
    if (key.contains('heal') || key.contains('calm')) {
      return TruLuraTokens.auraCyan;
    }
    if (key.contains('creator')) return TruLuraBrandColors.glowGold;
    return TruLuraTokens.auraViolet;
  }
}

class _HeroAuraFieldPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  const _HeroAuraFieldPainter({
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final haze = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: const Alignment(0, -0.72),
        radius: 1.05,
        colors: [
          accent.withValues(alpha: 0.24),
          secondary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, haze);

    final perimeter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accent.withValues(alpha: 0.22),
          secondary.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(34)),
      perimeter,
    );

    final dust = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.12 + i * 0.095);
      final y = size.height * (0.16 + ((i * 17) % 41) / 100);
      dust.color = (i.isEven ? accent : secondary).withValues(alpha: 0.055);
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.5, dust);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroAuraFieldPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.secondary != secondary;
  }
}

class _AvatarAuraRingPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  const _AvatarAuraRingPainter({
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + i * 0.25
        ..blendMode = BlendMode.plus
        ..color =
            (i.isEven ? accent : secondary).withValues(alpha: 0.18 - i * 0.04);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 116 + i * 18,
          height: 102 + i * 22,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarAuraRingPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.secondary != secondary;
  }
}

class _PresenceRhythmStrip extends StatelessWidget {
  final Color accent;
  final String mood;
  final String intent;

  const _PresenceRhythmStrip({
    required this.accent,
    required this.mood,
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final status = intent.toLowerCase().contains('creator')
        ? 'Cinematic Mode'
        : mood.toLowerCase().contains('calm') ||
                mood.toLowerCase().contains('heal')
            ? 'Grounded Mode'
            : 'Aura Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.14),
            cs.surfaceContainerHighest.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BreathingGlow(
            glowColor: accent,
            maxBlur: 16,
            minBlur: 7,
            maxAlpha: 0.22,
            minAlpha: 0.08,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: t.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyIndicator extends StatelessWidget {
  final String label;
  final Color accent;

  const _EnergyIndicator({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TruLuraIcon(
            glyph: TruLuraGlyph.moon,
            size: 13,
            active: true,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.86),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

class _IdentityChip extends StatelessWidget {
  final String label;
  final TruLuraGlyph glyph;
  final Color accent;

  const _IdentityChip({
    required this.label,
    required this.glyph,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.15),
            cs.surfaceContainerHighest.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.11),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TruLuraIcon(glyph: glyph, size: 14, active: true, color: accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

class _AuraSignaturePill extends StatelessWidget {
  final int strength;

  const _AuraSignaturePill({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: TruLuraTokens.auraPink.withValues(alpha: 0.32),
        ),
        color: TruLuraTokens.auraPink.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TruLuraIcon(
            glyph: TruLuraGlyph.aura,
            size: 18,
            active: true,
            color: TruLuraTokens.auraPink,
          ),
          const SizedBox(width: 9),
          Text(
            'Aura Signature · ${_rhythmCopy(strength)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TruLuraTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }

  String _rhythmCopy(int score) {
    if (score >= 82) return 'Deep aura rhythm';
    if (score >= 68) return 'Warm aura rhythm';
    return 'Soft aura opening';
  }
}
