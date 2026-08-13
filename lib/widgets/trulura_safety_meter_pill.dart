import 'package:flutter/material.dart';
import 'package:trulura/services/safety_meter_service.dart';
import 'package:trulura/theme.dart';

/// Subtle, non-alarmist safety meter pill.
class TruLuraSafetyMeterPill extends StatelessWidget {
  final TruSafetyMeter meter;
  final VoidCallback? onTap;

  const TruLuraSafetyMeterPill({super.key, required this.meter, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon) = _styleFor(meter.level, cs);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14), width: TruLuraSurfaces.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(meter.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: fg)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: fg.withValues(alpha: 0.8)),
            ],
          ],
        ),
      ),
    );
  }

  (Color bg, Color fg, IconData icon) _styleFor(TruSafetyMeterLevel level, ColorScheme cs) {
    switch (level) {
      case TruSafetyMeterLevel.strong:
        return (cs.primary.withValues(alpha: 0.14), cs.onSurface, Icons.verified_rounded);
      case TruSafetyMeterLevel.standard:
        return (cs.secondary.withValues(alpha: 0.12), cs.onSurface, Icons.shield_rounded);
      case TruSafetyMeterLevel.basic:
        return (cs.surfaceContainerHighest.withValues(alpha: 0.22), cs.onSurface, Icons.shield_outlined);
      case TruSafetyMeterLevel.threadStable:
        return (cs.primary.withValues(alpha: 0.12), cs.onSurface, Icons.shield_moon_rounded);
      case TruSafetyMeterLevel.threadCaution:
        return (cs.tertiary.withValues(alpha: 0.14), cs.onSurface, Icons.shield_rounded);
      case TruSafetyMeterLevel.threadElevated:
        return (cs.error.withValues(alpha: 0.14), cs.onSurface, Icons.report_gmailerrorred_rounded);
      case TruSafetyMeterLevel.unknown:
        return (cs.surfaceContainerHighest.withValues(alpha: 0.18), cs.onSurface, Icons.help_outline_rounded);
    }
  }
}
