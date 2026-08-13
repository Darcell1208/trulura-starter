import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/services/safety_center_service.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/tru_toggle.dart';

class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  final _svc = SafetyCenterService();
  final _reporting = ReportingService();
  bool _loading = true;
  TruSafetyCenterPrefs _prefs = const TruSafetyCenterPrefs();
  int _blockedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await _svc.getPrefs();
      final blocked = await _reporting.getBlockedUserIds();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _blockedCount = blocked.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SafetyCenterScreen._load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = _prefs;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        showClose: true,
        onBack: () =>
            TruNavigation.goBackOrReturn(context, fallback: AppRoutes.settings),
        onClose: () =>
            TruNavigation.closeModule(context, fallback: AppRoutes.settings),
        title: 'Safety Center',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            Text(
              'Protective, not restrictive — you control the boundaries.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.4),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Communication', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Message filtering',
                    subtitle: 'Gentle warnings for coercion, scams, explicit pressure.',
                    value: p.messageFilteringEnabled,
                    onChanged: (v) async {
                      await _svc.setMessageFilteringEnabled(v);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Anti-doxxing shield',
                    subtitle: 'Warn before sending phone numbers, emails, or addresses.',
                    value: p.antiDoxxingEnabled,
                    onChanged: (v) async {
                      await _svc.setAntiDoxxingEnabled(v);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Crisis support prompts',
                    subtitle: 'If distress language appears, offer resources (non-intrusive).',
                    value: p.crisisSupportEnabled,
                    onChanged: (v) async {
                      await _svc.setCrisisSupportEnabled(v);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Safety prompts',
                    subtitle: 'Show non-alarmist reminders when risk patterns appear.',
                    value: p.scamPromptsEnabled,
                    onChanged: (v) async {
                      await _svc.setScamPromptsEnabled(v);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Who can message you', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: TruLuraSurfaces.hairline),
                      ),
                      child: DropdownButton<TruDmPermission>(
                        value: p.dmPermission,
                        isExpanded: true,
                        items: TruDmPermission.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          await _svc.setDmPermission(v);
                          await _load();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(p.dmPermission.helper, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.3)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AuraShield', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Behavioral intelligence (local)',
                    subtitle: 'Detect coercion, manipulation cycles, and escalation patterns over time.',
                    value: p.auraShieldEnabled,
                    onChanged: (v) async {
                      await _svc.setAuraShieldEnabled(v);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: TruLuraSurfaces.hairline),
                    ),
                    child: Text(
                      'AuraShield runs locally, watches for repeated patterns instead of one-off messages, and surfaces soft warnings rather than automatic blocks.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Safety Meter detail view',
                    subtitle: 'Show deeper safety context when you choose to open it.',
                    value: p.showSafetyMeterDetails,
                    onChanged: (v) async {
                      await _svc.setShowSafetyMeterDetails(v);
                      await _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ephemeral messaging', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Allow self-destruct messages',
                    subtitle: 'Enable time-limited messages in private threads.',
                    value: p.ephemeralMessagingEnabled,
                    onChanged: (v) async {
                      await _svc.setEphemeralMessagingEnabled(v);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Screenshot blocking is coming soon - backend integration. For now, Trulura uses visibility + retention controls and gentle warnings instead.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interactions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Allow non-mutual sparks',
                    subtitle: 'If off, sparks require mutual interest signals first.',
                    value: p.allowNonMutualSparks,
                    onChanged: (v) async {
                      await _svc.setAllowNonMutualSparks(v);
                      await _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Blocked users', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('$_blockedCount blocked', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72))),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.push(
                      Uri(
                        path: AppRoutes.blockedUsers,
                        queryParameters: {
                          'returnTo': GoRouterState.of(context).uri.toString(),
                        },
                      ).toString(),
                    ),
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.3)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TruToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
