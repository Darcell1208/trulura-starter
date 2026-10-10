import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';

/// Editorial art is decorative; cards route to real features without invented activity.
class HomeCompanionRail extends StatelessWidget {
  const HomeCompanionRail({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 14, 16, 24),
      children: [
        _artCard(context,
            title: 'TruLura AI',
            asset: 'assets/images/trulura_companion_art.png',
            height: 350,
            description: 'A space to reflect and explore what’s on your mind.',
            action: 'Open companion',
            route: AppRoutes.aiCompanionHub),
        const SizedBox(height: 14),
        _artCard(context,
            title: 'Worlds',
            asset: 'assets/images/trulura_home_atmosphere.png',
            height: 210,
            description: 'Find your interests. Discover your people.',
            action: 'Explore worlds',
            route: AppRoutes.homeTab('explore')),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.live_tv_outlined, color: colors.primary),
              SizedBox(width: 10),
              Text('Live',
                  style: TextStyle(color: colors.onSurface, fontSize: 20))
            ]),
            const SizedBox(height: 10),
            Text('Explore live spaces.',
                style: TextStyle(color: colors.onSurfaceVariant)),
            TextButton(
                onPressed: () =>
                    TruNavigation.pushWithReturnTo(context, AppRoutes.live),
                child: const Text('Open Live →')),
          ]),
        ),
      ],
    );
  }

  Widget _artCard(BuildContext context,
      {required String title,
      required String asset,
      required double height,
      required String description,
      required String action,
      required String route}) {
    final colors = Theme.of(context).colorScheme;
    final illustrated =
        context.watch<AppProvider>().appearanceMode == 'trulura';
    return Container(
      height: illustrated ? height : null,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
      ),
      child:
          Stack(fit: illustrated ? StackFit.expand : StackFit.loose, children: [
        if (illustrated)
          Image.asset(asset, fit: BoxFit.cover, excludeFromSemantics: true),
        if (illustrated)
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Color(0x55060913),
                Color(0x10060913),
                Color(0xFF060913)
              ],
                      stops: [
                0,
                .35,
                1
              ]))),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: illustrated ? Colors.white : colors.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w500)),
                  if (illustrated)
                    const Spacer()
                  else
                    const SizedBox(height: 12),
                  Text(description,
                      style: TextStyle(
                          color: illustrated
                              ? const Color(0xFFE1DDED)
                              : colors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF612CF2),
                              foregroundColor: Colors.white),
                          onPressed: () =>
                              TruNavigation.pushWithReturnTo(context, route),
                          child: Text(action))),
                ])),
      ]),
    );
  }
}
