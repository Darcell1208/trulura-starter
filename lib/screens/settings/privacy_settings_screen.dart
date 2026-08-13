import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/identity_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _identity = IdentityService();
  User? _me;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await UserService().getCurrentUser();
      if (!mounted) return;
      setState(() {
        _me = me;
        _loading = false;
      });
    } catch (e) {
      debugPrint('PrivacySettingsScreen load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = _me;

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
        title: 'Privacy',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            Text('Control how visible you feel — without losing your core identity.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.4)),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Text(
                'Privacy controls help you choose how visible and persistent you want to feel. TruLura treats visibility as an emotional boundary, not a generic account setting.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _SettingRow(
                    title: 'Allow screenshots',
                    subtitle: 'Choose whether visual moments can be captured.',
                    trailing: TruToggle(
                      value: me?.allowScreenshots ?? true,
                      onChanged: (v) async {
                        await _identity.setPrivacy(allowScreenshots: v);
                        await _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingRow(
                    title: 'Self-destruct messages',
                    subtitle: 'Auto-delete sensitive exchanges after a short window.',
                    trailing: TruToggle(
                      value: me?.messageAutoDelete ?? false,
                      onChanged: (v) async {
                        await _identity.setPrivacy(messageAutoDelete: v);
                        await _load();
                      },
                    ),
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
                  Text('Profile visibility', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: TruLuraSurfaces.hairline),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TruProfileVisibility>(
                        value: me?.profileVisibility ?? TruProfileVisibility.public,
                        isExpanded: true,
                        items: TruProfileVisibility.values
                            .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          await _identity.setPrivacy(profileVisibility: v);
                          await _load();
                        },
                      ),
                    ),
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

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.3)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Align(
          alignment: Alignment.topRight,
          child: trailing,
        ),
      ],
    );
  }
}
