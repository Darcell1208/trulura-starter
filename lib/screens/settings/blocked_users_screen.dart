import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _reporting = ReportingService();
  bool _loading = true;
  List<String> _blocked = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ids = await _reporting.getBlockedUserIds();
      if (!mounted) return;
      setState(() {
        _blocked = ids.toList()..sort();
        _loading = false;
      });
    } catch (e) {
      debugPrint('BlockedUsersScreen._load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        showClose: true,
        onBack: () => TruNavigation.goBackOrReturn(
          context,
          fallback: AppRoutes.safetyCenter,
        ),
        onClose: () => TruNavigation.closeModule(
          context,
          fallback: AppRoutes.safetyCenter,
        ),
        title: 'Blocked users',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            Text('You won\'t see each other. Messaging and interactions are blocked.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.4)),
            const SizedBox(height: 14),
            const TruLuraGlassCard(
              radius: 22,
              padding: EdgeInsets.all(14),
              child: Text('Blocked people are removed from discovery, direct messaging, and lightweight social prompts. You can reverse that here anytime.'),
            ),
            const SizedBox(height: 14),
            if (!_loading && _blocked.isNotEmpty)
              TruLuraGlassCard(
                radius: 22,
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Blocking is private. People you block are removed from discovery and conversation surfaces, and you can quietly review those decisions here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ),
            if (!_loading && _blocked.isNotEmpty) const SizedBox(height: 14),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (!_loading && _blocked.isEmpty)
              TruLuraGlassCard(
                radius: 22,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        TruLuraIcon(glyph: TruLuraGlyph.shield, size: 18, active: true, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(child: Text('No blocked users yet.')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If someone crosses a boundary later, this is where you can quietly review and manage those decisions.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.35),
                    ),
                  ],
                ),
              ),
            if (!_loading)
              ..._blocked.map((id) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TruLuraGlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: FutureBuilder(
                              future: UserService().getUserById(id),
                              builder: (context, snapshot) {
                                final name = snapshot.data?.name;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name ?? 'User', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 2),
                                    Text(id, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70))),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () async {
                              await _reporting.unblockUser(id);
                              await _load();
                            },
                            child: const Text('Unblock'),
                          ),
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
