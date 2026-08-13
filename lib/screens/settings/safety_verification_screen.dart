import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/background_verification_service.dart';
import 'package:trulura/services/compliance_service.dart';
import 'package:trulura/services/identity_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

class SafetyVerificationScreen extends StatefulWidget {
  const SafetyVerificationScreen({super.key});

  @override
  State<SafetyVerificationScreen> createState() =>
      _SafetyVerificationScreenState();
}

class _SafetyVerificationScreenState extends State<SafetyVerificationScreen> {
  final _identity = IdentityService();
  final _compliance = ComplianceService();
  final _bg = BackgroundVerificationService();
  User? _me;
  bool _loading = true;
  TruCompliancePrefs? _compliancePrefs;
  TruBackgroundVerification _bgState = const TruBackgroundVerification();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await UserService().getCurrentUser();
      final prefs = await _compliance.getPrefs();
      final bg = me == null
          ? const TruBackgroundVerification()
          : await _bg.get(me.id);
      if (!mounted) return;
      final app = context.read<AppProvider>();
      await app.setHasAdvancedVerification(
        (me?.verificationLevel.index ?? 0) >=
            TruVerificationLevel.level2.index,
      );
      await app.setHasBackgroundVerification(
        bg.status == TruBackgroundCheckStatus.verified,
      );
      setState(() {
        _me = me;
        _compliancePrefs = prefs;
        _bgState = bg;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SafetyVerificationScreen load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final me = _me;
    final level = me?.verificationLevel ?? TruVerificationLevel.level0;
    final compliance = _compliancePrefs;
    final showVerification = me?.showVerificationBadge ?? true;
    final showTrust = me?.showTrustIndicator ?? true;
    final hideAll = !(showVerification || showTrust);

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
        title: 'Safety & Verification',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            Text(
              'Trust is layered. You control what you reveal.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TruLuraIcon(
                        glyph: TruLuraGlyph.shield,
                        size: 20,
                        active: true,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your verification level',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _LevelChip(level: level),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProgressTrack(level: level),
                  const SizedBox(height: 12),
                  Text(
                    'This is a local stub for now. Basic account use stays open, while creator and Luxe access build on top of these trust layers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  final next = TruVerificationLevel.values[
                                      (level.index + 1).clamp(
                                        0,
                                        TruVerificationLevel.values.length - 1,
                                      )];
                                  final updated =
                                      (me ??
                                              await UserService()
                                                  .getCurrentUser())
                                          ?.copyWith(
                                            verificationLevel: next,
                                            updatedAt: DateTime.now(),
                                          );
                                  if (updated != null) {
                                    await UserService().saveUser(updated);
                                  }
                                  await app.setHasAdvancedVerification(
                                    next.index >=
                                        TruVerificationLevel.level2.index,
                                  );
                                  await _load();
                                },
                          child: const Text('Advance level (stub)'),
                        ),
                      ),
                    ],
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
                  Text(
                    'What unlocks what',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _GateLine(
                    title: 'Basic account access',
                    subtitle:
                        'Home, profile, posting, and social discovery stay open without forced onboarding.',
                  ),
                  const SizedBox(height: 10),
                  _GateLine(
                    title: 'Creator approval requirement',
                    subtitle: app.creatorOnboardingComplete
                        ? (app.creatorApproved
                            ? 'Creator onboarding is complete and approval is active.'
                            : 'Creator onboarding is complete. Approval is still required for TruStudio tools.')
                        : 'Complete creator onboarding before advanced creator tools unlock.',
                  ),
                  const SizedBox(height: 10),
                  _GateLine(
                    title: 'Advanced verification requirement',
                    subtitle: app.hasAdvancedVerification
                        ? 'Advanced verification is marked complete for higher-trust spaces.'
                        : 'Required for Luxe and other elevated spaces.',
                  ),
                  const SizedBox(height: 10),
                  _GateLine(
                    title: 'Luxe access requirement',
                    subtitle: app.luxeEligible
                        ? 'Invite, membership, and advanced verification are all complete.'
                        : 'Luxe stays gated until invite, membership, and advanced verification are all in place.',
                  ),
                  const SizedBox(height: 10),
                  _GateLine(
                    title: 'Optional background verification',
                    subtitle: app.hasBackgroundVerification
                        ? 'Background verification is complete.'
                        : 'Optional extra trust layer for people who want it.',
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
                  Text(
                    'Background verification (optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Run through a trusted third-party provider. Results are never displayed as public shaming; you control where they appear.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _bgState.status ==
                                  TruBackgroundCheckStatus.verified
                              ? 'Status: verified'
                              : (_bgState.status ==
                                      TruBackgroundCheckStatus.requested
                                  ? 'Status: requested'
                                  : 'Status: off'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton(
                        onPressed: _loading || me == null
                            ? null
                            : () async {
                                final next = _bgState.status ==
                                        TruBackgroundCheckStatus.none
                                    ? _bgState.copyWith(
                                        status:
                                            TruBackgroundCheckStatus.requested,
                                      )
                                    : (_bgState.status ==
                                            TruBackgroundCheckStatus.requested
                                        ? _bgState.copyWith(
                                            status:
                                                TruBackgroundCheckStatus
                                                    .verified,
                                            verifiedAt: DateTime.now(),
                                          )
                                        : const TruBackgroundVerification());
                                await _bg.set(me.id, next);
                                await app.setHasBackgroundVerification(
                                  next.status ==
                                      TruBackgroundCheckStatus.verified,
                                );
                                await _load();
                              },
                        child: Text(
                          _bgState.status == TruBackgroundCheckStatus.none
                              ? 'Request (stub)'
                              : (_bgState.status ==
                                      TruBackgroundCheckStatus.requested
                                  ? 'Mark verified (stub)'
                                  : 'Reset'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<TruBackgroundShareScope>(
                      value: _bgState.shareScope,
                      isExpanded: true,
                      items: TruBackgroundShareScope.values
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text('Visible: ${v.label}'),
                            ),
                          )
                          .toList(),
                      onChanged: me == null
                          ? null
                          : (v) async {
                              if (v == null) return;
                              await _bg.set(
                                me.id,
                                _bgState.copyWith(shareScope: v),
                              );
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
                  Text(
                    'Local access state',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Creator onboarding complete',
                    value: app.creatorOnboardingComplete,
                    onChanged: (v) => app.setCreatorOnboardingComplete(v),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Advanced verification complete',
                    value: app.hasAdvancedVerification,
                    onChanged: (v) => app.setHasAdvancedVerification(v),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Background verification complete',
                    value: app.hasBackgroundVerification,
                    onChanged: (v) => app.setHasBackgroundVerification(v),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Luxe invite approved',
                    value: app.hasLuxeInvite,
                    onChanged: (v) => app.setHasLuxeInvite(v),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Luxe membership active',
                    value: app.hasLuxeSubscription,
                    onChanged: (v) => app.setHasLuxeSubscription(v),
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
                  Text(
                    'Visibility',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Hide all trust indicators',
                    value: hideAll,
                    onChanged: (v) async {
                      if (v) {
                        await _identity.setTrustVisibility(
                          showVerification: false,
                          showTrust: false,
                        );
                      } else {
                        await _identity.setTrustVisibility(
                          showVerification: true,
                          showTrust: true,
                        );
                      }
                      await _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Show verification badge',
                    value: showVerification,
                    onChanged: hideAll
                        ? (_) {}
                        : (v) async {
                            await _identity.setTrustVisibility(
                              showVerification: v,
                            );
                            await _load();
                          },
                  ),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    title: 'Show trust indicator',
                    value: showTrust,
                    onChanged: hideAll
                        ? (_) {}
                        : (v) async {
                            await _identity.setTrustVisibility(
                              showTrust: v,
                            );
                            await _load();
                          },
                  ),
                  if (hideAll) ...[
                    const SizedBox(height: 8),
                    Text(
                      'All trust signals are hidden across your profile and posts.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        height: 1.3,
                      ),
                    ),
                  ],
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
                  Text(
                    'Consent & Platform Protection',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Higher-trust spaces keep different requirements separate: creator approval for TruStudio, advanced verification for Luxe, optional background verification for extra trust, and consent prompts for elevated spaces.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          compliance?.termsAcceptedAt == null
                              ? 'Terms: not accepted'
                              : 'Terms: accepted',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton(
                        onPressed: compliance?.termsAcceptedAt != null
                            ? null
                            : () async {
                                await _compliance.acceptTerms();
                                await _load();
                              },
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final TruVerificationLevel level;
  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Text(
        level.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final TruVerificationLevel level;
  const _ProgressTrack({required this.level});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (level.index + 1) / TruVerificationLevel.values.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.20),
        valueColor: AlwaysStoppedAnimation<Color>(
          cs.primary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _GateLine extends StatelessWidget {
  final String title;
  final String subtitle;

  const _GateLine({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.70),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TruToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
