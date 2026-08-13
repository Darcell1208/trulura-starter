import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';

/// Spec component: TruluraMessageBubble.
class TruluraMessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final bool failed;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;
  final String? meta;

  const TruluraMessageBubble({
    super.key,
    required this.content,
    required this.isMe,
    this.failed = false,
    this.onRetry,
    this.onLongPress,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: onLongPress,
              child: TruLuraGlassCard(
                mode: TruLuraMode.aura,
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                fillAOverride: isMe ? TruLuraTokens.auraViolet.withValues(alpha: 0.18) : null,
                fillBOverride: isMe ? TruLuraTokens.auraPink.withValues(alpha: 0.12) : null,
                child: Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface, height: 1.35)),
              ),
            ),
            if (meta != null && meta!.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(meta!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.62), fontWeight: FontWeight.w800)),
            ],
            if (failed && onRetry != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onRetry,
                child: Text('Failed to send • Tap to retry', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.error.withValues(alpha: 0.86), fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
