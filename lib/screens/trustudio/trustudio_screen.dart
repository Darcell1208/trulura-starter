import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class TruStudioScreen extends StatelessWidget {
  const TruStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    if (!(app.creatorModeEnabled &&
        app.creatorOnboardingComplete &&
        app.creatorApproved)) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
            onPressed: () => TruNavigation.goBackOrReturn(context),
          ),
          actions: [
            IconButton(
              icon: const TruLuraIcon(glyph: TruLuraGlyph.close, size: 20),
              onPressed: () => TruNavigation.closeModule(context),
            ),
          ],
          title: const Text('TruStudio'),
        ),
        body: TruLuraLayeredBackground(
          tone: TruLuraModeTone.explore,
          mode: TruLuraMode.trending,
          modeAccent: TruLuraBrandColors.glowGold.withValues(alpha: 0.12),
          child: Center(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TruStudio requires creator onboarding and approval before advanced tools unlock.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.78),
                        height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.creatorModeEnabled
                        ? app.creatorOnboardingComplete
                            ? 'Creator interest is on. Approval is still pending.'
                            : 'Creator interest is on. Complete onboarding next.'
                        : 'Basic posting stays open. Turn on Creator Mode in Settings when you want to apply.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.68),
                        height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final soft = app.softModeEnabled;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
            onPressed: () => TruNavigation.goBackOrReturn(context),
          ),
          actions: [
            IconButton(
              icon: const TruLuraIcon(glyph: TruLuraGlyph.close, size: 20),
              onPressed: () => TruNavigation.closeModule(context),
            ),
          ],
          title: const Text('TruStudio'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: cs.primary.withValues(alpha: soft ? 0.6 : 1),
            dividerColor: Colors.transparent,
            labelColor: cs.onSurface,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.65),
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Live Tools'),
              Tab(text: 'Subscribers'),
              Tab(text: 'Brand Deals'),
              Tab(text: 'Content'),
              Tab(text: 'Payouts'),
            ],
          ),
        ),
        body: TruLuraLayeredBackground(
          // TruStudio: cinematic studio (more structured, less neon)
          tone: TruLuraModeTone.explore,
          mode: TruLuraMode.trending,
          modeAccent: TruLuraBrandColors.glowGold.withValues(alpha: 0.12),
          child: TabBarView(
            children: [
              _StudioPanel(
                  title: 'Dashboard',
                  soft: soft,
                  children: const [_MetricRow()]),
              _StudioPanel(title: 'Live Tools', soft: soft, children: const [
                _StudioPlaceholder(
                    text:
                        'Creator live overlays, scene controls, and moderation tools live here.')
              ]),
              _StudioPanel(title: 'Subscribers', soft: soft, children: const [
                _StudioPlaceholder(
                    text: 'Subscriber tiers, perks, and retention insights.')
              ]),
              _StudioPanel(title: 'Brand Deals', soft: soft, children: const [
                _StudioPlaceholder(
                    text: 'Deal pipeline, deliverables, and sponsor messaging.')
              ]),
              _StudioPanel(title: 'Content', soft: soft, children: const [
                _StudioPlaceholder(
                    text: 'Upload queue, scheduling, and content library.')
              ]),
              _StudioPanel(title: 'Payouts', soft: soft, children: const [
                _StudioPlaceholder(
                    text: 'Payout history, balance, and payment settings.')
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioPanel extends StatelessWidget {
  final String title;
  final bool soft;
  final List<Widget> children;

  const _StudioPanel(
      {required this.title, required this.soft, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = soft
        ? cs.outline.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.10);
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(letterSpacing: -0.6)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            border: Border.all(color: borderColor),
            boxShadow: soft
                ? TruLuraEffects.premiumCardDepth(Colors.black, intensity: 0.28)
                : TruLuraEffects.premiumCardDepth(
                    TruLuraBrandColors.nebulaIndigo,
                    intensity: 0.35),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const TruLuraIcon(glyph: TruLuraGlyph.shield, size: 20),
            title: const Text('Verification status'),
            subtitle: Text(soft
                ? 'Soft Mode active: visuals minimized.'
                : 'Creator verified: TruStudio tools unlocked.'),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context) {
    // Soft Mode requirement: no animated graphs. We keep static metric cards.
    return Row(
      children: const [
        Expanded(
            child: _MetricCard(
                label: 'Views', value: '12.4K', icon: TruLuraGlyph.insights)),
        SizedBox(width: 12),
        Expanded(
            child: _MetricCard(
                label: 'Subs', value: '328', icon: TruLuraGlyph.groups)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final TruLuraGlyph icon;

  const _MetricCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surface.withValues(alpha: 0.35),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          TruLuraIcon(
              glyph: icon,
              size: 20,
              active: true,
              color: cs.onSurface.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioPlaceholder extends StatelessWidget {
  final String text;

  const _StudioPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.72), height: 1.45)),
    );
  }
}
