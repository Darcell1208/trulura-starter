import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

// Re-export the spec-aligned public component library so callers can import a
// single file for both the lightweight kit and the app-wide components.
export 'package:trulura/trulura_components.dart';

/// Lightweight TruLura UI kit.
///
/// This file intentionally *reuses* the existing project theme + glass/background
/// widgets. It provides the simplified API you shared (palette + pills/buttons)
/// without introducing duplicate class names that would conflict across imports.
///
/// Note: the app already defines a **mode-aware** `TruLuraPalette` model in
/// `providers/trulura_mode_controller.dart`. To avoid import ambiguity, the
/// UI-kit palette is named [TruLuraKitPalette].
class TruLuraKitPalette {
  static const bgTop = TruLuraTokens.ink;
  static const bgMid = TruLuraTokens.deepIndigo;
  static const bgBottom = TruLuraTokens.nebula;

  static const glass = Color(0x22FFFFFF);
  static const stroke = Color(0x33FFFFFF);

  static const text = TruLuraTokens.textPrimary;
  static const textDim = Color(0xB3F2F2FF);

  static const purple = TruLuraTokens.auraViolet;
  static const pink = TruLuraTokens.auraPink;
  static const cyan = TruLuraTokens.auraCyan;
  static const mint = Color(0xFF3DFFB5);

  static const danger = Color(0xFFFF4B6E);
  static const warn = Color(0xFFFFC857);
  static const ok = Color(0xFF33D17A);

  static LinearGradient auroraGradient({double rotate = 0}) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgTop, bgMid, bgBottom],
        stops: [0.0, 0.55, 1.0],
      );

  static LinearGradient ctaGradient() => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [purple, pink],
      );
}

/// Full-screen TruLura background wrapper.
///
/// Uses the project’s cinematic layered background while keeping the simplified
/// `TruLuraBackground(child: ...)` API from your mockups.
class TruLuraBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const TruLuraBackground({super.key, required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => TruLuraLayeredBackground(padding: padding, child: child);
}

class TruPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? glowColor;
  final bool selected;
  final VoidCallback? onTap;

  const TruPill({
    super.key,
    required this.label,
    this.icon,
    this.glowColor,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = glowColor ?? TruLuraKitPalette.purple;
    final bg = selected ? g.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08);
    final border = selected ? g.withValues(alpha: 0.55) : TruLuraKitPalette.stroke;
    final glow = selected ? [BoxShadow(color: g.withValues(alpha: 0.28), blurRadius: 20, spreadRadius: 1)] : const <BoxShadow>[];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border), boxShadow: glow),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: TruLuraKitPalette.text),
              const SizedBox(width: 6),
            ],
            Text(label, style: const TextStyle(color: TruLuraKitPalette.text, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class TruPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const TruPrimaryButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: TruLuraKitPalette.ctaGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: TruLuraKitPalette.pink.withValues(alpha: 0.22), blurRadius: 22, spreadRadius: 2)],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: TruLuraKitPalette.text),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(color: TruLuraKitPalette.text, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class TruSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const TruSecondaryButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TruLuraGlassCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        tint: Colors.white.withValues(alpha: 0.08),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: TruLuraKitPalette.text),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(color: TruLuraKitPalette.text, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class TruPercentBadge extends StatelessWidget {
  final int percent;
  final Color? glowColor;

  const TruPercentBadge({super.key, required this.percent, this.glowColor});

  @override
  Widget build(BuildContext context) {
    final g = glowColor ?? TruLuraKitPalette.pink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: g.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: g.withValues(alpha: 0.55)),
        boxShadow: [BoxShadow(color: g.withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 1)],
      ),
      child: Text('$percent%', style: const TextStyle(color: TruLuraKitPalette.text, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}
