import 'package:flutter/material.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

/// Spec component: TruluraScreenShell.
///
/// Consistent layout wrapper for main tab surfaces:
/// - layered cosmic background
/// - safe area
/// - optional top bar slot
/// - body
/// - optional bottom nav slot
class TruluraScreenShell extends StatelessWidget {
  final PreferredSizeWidget? topBar;
  final Widget body;
  final Widget? bottomNav;
  final Widget? drawer;
  final EdgeInsets contentPadding;

  const TruluraScreenShell({
    super.key,
    this.topBar,
    required this.body,
    this.bottomNav,
    this.drawer,
    this.contentPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: drawer,
      appBar: topBar,
      body: TruLuraLayeredBackground(
        padding: contentPadding,
        child: SafeArea(
          top: topBar == null,
          bottom: bottomNav == null,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}
