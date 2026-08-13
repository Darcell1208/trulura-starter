import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Reusable loading/empty/error/no-results widgets used across Trulura tabs.
///
/// Design goals:
/// - Keep screens feeling alive even when data is absent
/// - Preserve TruLura glass language (no generic spinners unless tiny)
/// - Avoid splash effects (use GestureDetector / InkWell with transparent overlay)
class TruScreenState {
  static const EdgeInsets defaultPadding = AppSpacing.paddingMd;
}

/// Small, developer-friendly UI-state override mechanism.
///
/// Usage (any route): append `?ui=empty` / `?ui=loading` / `?ui=action`.
/// If omitted or invalid, screens render their normal (data-driven) default.
enum TruUiState { def, empty, loading, action }

TruUiState truParseUiState(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'empty':
      return TruUiState.empty;
    case 'loading':
      return TruUiState.loading;
    case 'action':
      return TruUiState.action;
    case 'default':
    case 'def':
    case '':
      return TruUiState.def;
    default:
      return TruUiState.def;
  }
}

class TruStateAction {
  final String label;
  final TruLuraGlyph glyph;
  final VoidCallback? onTap;
  final bool primary;

  const TruStateAction(
      {required this.label,
      required this.glyph,
      required this.onTap,
      this.primary = false});
}

class TruStatePanel extends StatelessWidget {
  final TruLuraModeTone tone;
  final TruLuraGlyph glyph;
  final String title;
  final String message;
  final List<TruStateAction> actions;
  final EdgeInsets padding;

  const TruStatePanel({
    super.key,
    this.tone = TruLuraModeTone.aura,
    required this.glyph,
    required this.title,
    required this.message,
    this.actions = const <TruStateAction>[],
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: TruLuraGlassCard(
          tone: tone,
          radius: 26,
          depth: true,
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    cs.primary.withValues(alpha: 0.22),
                    cs.secondary.withValues(alpha: 0.16)
                  ]),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: TruLuraSurfaces.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.18),
                      blurRadius: 32,
                      spreadRadius: -14,
                    ),
                  ],
                ),
                child: Center(
                    child: TruLuraIcon(
                        glyph: glyph,
                        size: 30,
                        active: true,
                        color: cs.onSurface.withValues(alpha: 0.90))),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72), height: 1.45),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: actions
                      .map((a) => _TruStateActionButton(action: a))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TruStateActionButton extends StatefulWidget {
  final TruStateAction action;
  const _TruStateActionButton({required this.action});

  @override
  State<_TruStateActionButton> createState() => _TruStateActionButtonState();
}

class _TruStateActionButtonState extends State<_TruStateActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = widget.action;
    final enabled = a.onTap != null;
    return GestureDetector(
      onTap: enabled ? a.onTap : null,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: a.primary
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                  boxShadow: [
                    BoxShadow(
                        color: cs.secondary.withValues(alpha: 0.28),
                        blurRadius: 22,
                        spreadRadius: -10,
                        offset: const Offset(0, 14))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TruLuraIcon(
                        glyph: a.glyph,
                        size: 18,
                        active: true,
                        color: Colors.white),
                    const SizedBox(width: 10),
                    Text(a.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2)),
                  ],
                ),
              )
            : TruLuraGlassCard(
                radius: 999,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TruLuraIcon(
                        glyph: a.glyph,
                        size: 18,
                        active: true,
                        color: cs.onSurface
                            .withValues(alpha: enabled ? 0.90 : 0.45)),
                    const SizedBox(width: 10),
                    Text(a.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface
                                .withValues(alpha: enabled ? 0.90 : 0.45),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2)),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A lightweight shimmer that does NOT require any external packages.
///
/// This is intentionally subtle (Trulura is neon-glass, not flashy skeletons).
class TruShimmer extends StatefulWidget {
  final Widget child;
  final Duration period;

  const TruShimmer(
      {super.key,
      required this.child,
      this.period = const Duration(milliseconds: 1250)});

  @override
  State<TruShimmer> createState() => _TruShimmerState();
}

class _TruShimmerState extends State<TruShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // Move gradient left -> right.
        final dx = (t * 2) - 1; // -1..1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final w = rect.width;
            final start = Alignment(-1.0 + dx, -0.2);
            final end = Alignment(1.0 + dx, 0.2);
            return LinearGradient(
              begin: start,
              end: end,
              colors: [
                cs.onSurface.withValues(alpha: 0.08),
                cs.onSurface.withValues(alpha: 0.20),
                cs.onSurface.withValues(alpha: 0.08),
              ],
              stops: const [0.2, 0.5, 0.8],
              transform: _ScaleGradientTransform(
                  scaleX: math.max(1, w / 220), scaleY: 1),
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}

class _ScaleGradientTransform extends GradientTransform {
  final double scaleX;
  final double scaleY;
  const _ScaleGradientTransform({required this.scaleX, required this.scaleY});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.identity()..scaleByDouble(scaleX, scaleY, 1.0, 1.0);
}

class TruSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const TruSkeletonBox(
      {super.key, required this.width, required this.height, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: TruLuraSurfaces.hairline),
      ),
    );
  }
}

class TruSkeletonCircle extends StatelessWidget {
  final double size;
  const TruSkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: TruLuraSurfaces.hairline),
      ),
    );
  }
}

class TruInlineBanner extends StatelessWidget {
  final TruLuraGlyph glyph;
  final String text;
  final VoidCallback? onTap;

  const TruInlineBanner(
      {super.key, required this.glyph, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          TruLuraIcon(
              glyph: glyph,
              size: 18,
              active: true,
              color: cs.onSurface.withValues(alpha: 0.92)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withValues(alpha: 0.86),
                      height: 1.25))),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            _BannerButton(onTap: onTap!),
          ],
        ],
      ),
    );
  }
}

class _BannerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BannerButton({required this.onTap});

  @override
  State<_BannerButton> createState() => _BannerButtonState();
}

class _BannerButtonState extends State<_BannerButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.98 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(colors: [
              cs.primary.withValues(alpha: 0.92),
              cs.secondary.withValues(alpha: 0.92)
            ]),
          ),
          child: Text('Manage',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2)),
        ),
      ),
    );
  }
}

void truLogStateError(String scope, Object error, [StackTrace? st]) {
  debugPrint('[$scope] $error');
  if (st != null) debugPrint(st.toString());
}
