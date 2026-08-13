import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// A premium, cosmic “orb-style” chip.
///
/// Designed for mood/vibe selection: a glowing circular orb with a label.
/// Use [tone] to map glow colors to Aura/Sync/Explore.
class TruLuraOrbChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final TruLuraGlyph? glyph;
  final TruLuraModeTone tone;

  /// Orb diameter.
  final double size;

  /// If true, renders label to the right (useful inline in cards).
  final bool compact;

  const TruLuraOrbChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.glyph,
    this.tone = TruLuraModeTone.aura,
    this.size = 44,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final (a, b) = tone.resolve(cs);
    final app = context.watch<AppProvider>();

    final orb = _Orb(
      size: size,
      selected: selected,
      a: a,
      b: b,
      glyph: glyph,
      brightness: brightness,
      glowScale: app.glowScale,
    );

    final labelWidget = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 220 : (size * 2.2).clamp(88, 140)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: compact ? TextAlign.left : TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );

    final content = compact
        ? Row(mainAxisSize: MainAxisSize.min, children: [orb, const SizedBox(width: 10), labelWidget])
        : Column(mainAxisSize: MainAxisSize.min, children: [orb, const SizedBox(height: 10), labelWidget]);

    final duration = app.softModeEnabled ? const Duration(milliseconds: 360) : const Duration(milliseconds: 180);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: duration,
        curve: Curves.easeOutCubic,
        opacity: selected ? 1.0 : (brightness == Brightness.dark ? 0.92 : 0.96),
        child: app.softModeEnabled
            ? content
            : AnimatedScale(duration: duration, curve: Curves.easeOutCubic, scale: selected ? 1.04 : 1.0, child: content),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final bool selected;
  final Color a;
  final Color b;
  final TruLuraGlyph? glyph;
  final Brightness brightness;
  final double glowScale;

  const _Orb({
    required this.size,
    required this.selected,
    required this.a,
    required this.b,
    required this.glyph,
    required this.brightness,
    required this.glowScale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inner = size * 0.76;
    final glowIntensity = (selected ? 1.55 : 0.85) * glowScale;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [a.withValues(alpha: 0.30), b.withValues(alpha: 0.18), Colors.transparent],
                  stops: const [0, 0.58, 1],
                ),
              ),
            ),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [a.withValues(alpha: selected ? 0.95 : 0.82), b.withValues(alpha: selected ? 0.62 : 0.48), cs.surface.withValues(alpha: 0.20)],
                stops: const [0, 0.65, 1],
              ),
              boxShadow: [
                ...TruLuraEffects.multiAuraGlow(a, b, intensity: glowIntensity),
                if (selected)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.22 : 0.10), width: 1),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: TruLuraIcon(glyph: glyph ?? TruLuraGlyph.spark, size: size * 0.38, active: selected, color: Colors.white.withValues(alpha: selected ? 0.96 : 0.88)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
