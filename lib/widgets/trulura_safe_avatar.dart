import 'package:flutter/material.dart';

/// A resilient circular avatar that never asserts/crashes when an image fails.
///
/// Use this instead of `CircleAvatar(backgroundImage: ...)` when the image may be
/// null, empty, or a network image that can 404.
class TruLuraSafeAvatar extends StatelessWidget {
  final double radius;
  final ImageProvider? image;
  final Widget? fallback;
  final Color? backgroundColor;

  const TruLuraSafeAvatar(
      {super.key,
      required this.radius,
      required this.image,
      this.fallback,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.75);
    final fallbackWidget = Center(
        child: fallback ??
            Icon(Icons.person,
                size: radius,
                color: Theme.of(context).colorScheme.onSurfaceVariant));

    return SizedBox.square(
      dimension: radius * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: ClipOval(
          child: image == null
              ? fallbackWidget
              : Image(
                  image: image!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallbackWidget,
                ),
        ),
      ),
    );
  }
}

/// Selects the correct loader for a stored profile image reference.
ImageProvider? profileImageProvider(String? source) {
  final value = source?.trim() ?? '';
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(value);
  }
  return AssetImage(value);
}
