import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

/// Compact, glassy “tag pill” used for metadata labels (e.g., filters, traits).
///
/// Visual spec (from your snippet):
/// - pill radius 999
/// - ink fill @ ~0.26 alpha
/// - thin white stroke @ ~0.14 alpha
class TagPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final EdgeInsetsGeometry padding;

  const TagPill({
    super.key,
    required this.icon,
    required this.text,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: TruLuraTokens.ink.withValues(alpha: 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TruLuraTokens.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: TruLuraTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
