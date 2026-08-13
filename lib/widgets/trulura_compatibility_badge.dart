import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

/// Spec component: TruluraCompatibilityBadge.
///
/// A compact compatibility indicator with glow levels.
class TruluraCompatibilityBadge extends StatelessWidget {
  final int percent;
  final String? label;
  final bool compact;

  const TruluraCompatibilityBadge({
    super.key,
    required this.percent,
    this.label,
    this.compact = true,
  });

  Color _glowA(ColorScheme cs) {
    if (percent >= 85) return TruLuraTokens.auraPink;
    if (percent >= 70) return TruLuraTokens.auraViolet;
    if (percent >= 55) return TruLuraTokens.auraCyan;
    return cs.onSurface.withValues(alpha: 0.35);
  }

  Color _glowB(ColorScheme cs) {
    if (percent >= 85) return TruLuraTokens.auraViolet;
    if (percent >= 70) return TruLuraTokens.auraCyan;
    if (percent >= 55) return TruLuraTokens.auraViolet;
    return cs.onSurface.withValues(alpha: 0.20);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = _glowA(cs);
    final b = _glowB(cs);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 7 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a.withValues(alpha: 0.95), b.withValues(alpha: 0.95)]),
        boxShadow: TruLuraTokens.softGlow(a),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: TruLuraSurfaces.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$percent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.2)),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(label!, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
