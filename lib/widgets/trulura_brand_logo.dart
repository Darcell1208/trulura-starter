import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

/// TruLura brand logo with a subtle neon bloom.
///
/// This is intentionally asset-driven so you can swap to the exact concept
/// logo by only changing [TruLuraAssets.logoSquare] (or passing [assetPath]).
class TruLuraBrandLogo extends StatelessWidget {
  final String? assetPath;
  final double size;
  final double radius;

  /// When true, adds a soft glow + a glassy stroke to match the reference look.
  final bool neon;

  const TruLuraBrandLogo({super.key, this.assetPath, this.size = 40, this.radius = 14, this.neon = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final path = assetPath ?? TruLuraAssets.logoSquare;

    final child = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(path, width: size, height: size, fit: BoxFit.cover),
    );

    if (!neon) return child;

    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: TruLuraBrandColors.neonPurple.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 0),
            BoxShadow(color: TruLuraBrandColors.sparkMagenta.withValues(alpha: 0.18), blurRadius: 28, spreadRadius: 0),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.12), width: 0.8),
                  ),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 0.0001, sigmaY: 0.0001), child: const SizedBox()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
