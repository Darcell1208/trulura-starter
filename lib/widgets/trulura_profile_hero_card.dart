import 'dart:math' as math;
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
  final VoidCallback? onEditProfile;

  const TruluraProfileHeroCard({
    super.key,
    required this.name,
    required this.handle,
    required this.bio,
    required this.avatarPath,
    required this.auraStrength,
    required this.onOpenSettings,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final illustrated = app.appearanceMode == 'trulura';
    final user = app.currentUser;
    final mood = (user?.moodTags.isNotEmpty ?? false)
        ? user!.moodTags.first
        : 'Reflective';
    final vibe = user?.temperament.label ?? 'Old Soul';
    final intent =
        (user?.intents.isNotEmpty ?? false) ? user!.intents.first : 'Social';
    final identityAccent = _identityAccent(mood, intent);
    final avatar = BreathingGlow(
      enabled: illustrated && !app.softModeEnabled && !MediaQuery.disableAnimationsOf(context),
      glowColor: identityAccent,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(shape: BoxShape.circle,
          gradient: SweepGradient(colors: [Color(0xFFF6B9FF), Color(0xFFB454FF), Color(0xFF69DFFF), Color(0xFFF6B9FF)])),
        child: AuraAvatar(image: avatarPath, compatibility: auraStrength, size: 116),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 150, child: CustomPaint(
            painter: illustrated ? const _ProfileNebulaPainter() : null,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [identityAccent.withValues(alpha: illustrated ? 0.12 : 0.07), cs.surface.withValues(alpha: 0.05)])),
              child: Align(alignment: Alignment.topRight,
                child: Padding(padding: const EdgeInsets.all(12), child: IconButton.filledTonal(
                  onPressed: onOpenSettings, tooltip: 'Profile Settings',
                  icon: const TruLuraIcon(glyph: TruLuraGlyph.filter, size: 20)))),
            ),
          )),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final details = Column(
                crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Text(name, textAlign: wide ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600)),
                  if ((handle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(handle!, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                  if (bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(bio, textAlign: wide ? TextAlign.left : TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],
                  const SizedBox(height: 18),
                  Wrap(alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                    spacing: 8, runSpacing: 8, children: [
                      _IdentityChip(label: vibe, glyph: TruLuraGlyph.spark, accent: identityAccent),
                      _IdentityChip(label: intent, glyph: TruLuraGlyph.aura, accent: cs.primary),
                      _EnergyIndicator(label: mood.isEmpty ? 'Reflective' : mood[0].toUpperCase() + mood.substring(1), accent: identityAccent),
                    ]),
                  if (onEditProfile != null) ...[
                    const SizedBox(height: 18),
                    OutlinedButton.icon(onPressed: onEditProfile,
                      icon: const TruLuraIcon(glyph: TruLuraGlyph.edit, size: 18),
                      label: const Text('Edit Profile')),
                  ],
                ],
              );
              final portrait = Transform.translate(offset: const Offset(0, -30), child: avatar);
              if (wide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                portrait, const SizedBox(width: 28),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 20), child: details)),
              ]);
              return Column(children: [portrait, details]);
            },
          )),
        ]),
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

/// Stable star positions keep the atmosphere calm while the existing halo breathes.
class _ProfileNebulaPainter extends CustomPainter {
  const _ProfileNebulaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF100724), Color(0xFF171044), Color(0xFF090B24)],
          ).createShader(rect));
    final random = math.Random(42);
    // Many overlapping translucent clouds give the field texture and depth.
    for (var i = 0; i < 54; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * (0.08 + 0.52 * (1 - x / size.width)) +
          random.nextDouble() * 100 -
          50;
      final radius = 35 + random.nextDouble() * 100;
      final color = [
        const Color(0xFF8E31DE),
        const Color(0xFF245CFF),
        const Color(0xFFDE4EC3)
      ][i % 3];
      canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: 0.09),
                color.withValues(alpha: 0)
              ],
            ).createShader(
                Rect.fromCircle(center: Offset(x, y), radius: radius)));
    }
    for (var i = 0; i < 230; i++) {
      final point = Offset(
          random.nextDouble() * size.width, random.nextDouble() * size.height);
      final alpha = point.dy > size.height * 0.62
          ? 0.18
          : 0.25 + random.nextDouble() * 0.5;
      final color =
          i % 3 == 0 ? const Color(0xFFD89CFF) : const Color(0xFFBADEFF);
      canvas.drawCircle(
          point,
          i % 19 == 0 ? 1.3 : 0.35 + random.nextDouble() * 0.55,
          Paint()..color = color.withValues(alpha: alpha));
      if (i % 47 == 0 && point.dy < size.height * 0.6) {
        final glow = Rect.fromCircle(center: point, radius: 13);
        canvas.drawCircle(
            point,
            13,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  color.withValues(alpha: 0.5),
                  color.withValues(alpha: 0)
                ],
              ).createShader(glow));
        final paint = Paint()
          ..color = color.withValues(alpha: 0.7)
          ..strokeWidth = 0.6;
        canvas.drawLine(
            point - const Offset(4, 0), point + const Offset(4, 0), paint);
        canvas.drawLine(
            point - const Offset(0, 6), point + const Offset(0, 6), paint);
      }
    }
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0x000B081D), Color(0xD90B081D)],
            stops: [0, 0.4, 1],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ProfileNebulaPainter oldDelegate) => false;
}
