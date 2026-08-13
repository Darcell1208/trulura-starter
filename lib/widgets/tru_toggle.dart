import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

class TruToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const TruToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      child: Align(
        alignment: Alignment.centerRight,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeThumbColor: TruLuraBrandColors.neonPurple,
          activeTrackColor: TruLuraBrandColors.neonPurple.withValues(alpha: 0.45),
          inactiveThumbColor: cs.onSurfaceVariant.withValues(alpha: 0.8),
          inactiveTrackColor: cs.onSurfaceVariant.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
