import 'package:flutter/material.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraEmptyStateCard.
///
/// This is a thin wrapper around the existing `TruStatePanel` so screens don’t
/// reinvent empty-state visuals.
class TruluraEmptyStateCard extends StatelessWidget {
  final TruLuraGlyph icon;
  final String title;
  final String message;
  final List<TruStateAction> actions;

  const TruluraEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const <TruStateAction>[],
  });

  @override
  Widget build(BuildContext context) {
    return TruStatePanel(
      glyph: icon,
      title: title,
      message: message,
      actions: actions,
    );
  }
}
