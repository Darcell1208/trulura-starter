import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/tag_pill.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_status_badge.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/services/compliance_service.dart';

class ExperienceModesScreen extends StatelessWidget {
  const ExperienceModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = context.watch<ExperienceModeController>();
    final p = kTruLuraPalettes[TruLuraMode.aura]!;
    final enabled = modes.enabledModes;
    final active = modes.activeMode;

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
        title: 'Experience Modes',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            TruLuraGlassCard(
              paletteMode: TruLuraMode.aura,
              depth: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your active worlds', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: p.text)),
                  const SizedBox(height: 10),
                  Text(
                    'Turn on multiple modes — one identity, different contexts. Locked modes show why, and what unlocks them.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: enabled.isEmpty
                        ? const [TagPill(icon: Icons.auto_awesome, text: 'Social')]
                        : enabled.map((m) => TagPill(icon: Icons.auto_awesome, text: m.label)).toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Row(
                      children: [
                        TruLuraIcon(glyph: active.glyph, size: 18, active: true, color: TruLuraTokens.textPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active mode', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.muted, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(active.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: p.text, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                            ],
                          ),
                        ),
                        Text(active.basePermissions().feedKind.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.muted, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (modes.isLoading) ...[
              const _ModeSkeleton(),
              const SizedBox(height: 12),
              const _ModeSkeleton(),
            ] else ...[
              for (final m in TruExperienceMode.values) ...[
                ExperienceModeCard(mode: m),
                const SizedBox(height: 12),
              ]
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

Future<bool> _showComplianceSheet(BuildContext context, TruComplianceRequirement req) async {
  final cs = Theme.of(context).colorScheme;
  final p = kTruLuraPalettes[TruLuraMode.aura]!;
  final compliance = ComplianceService();

  bool acceptTerms = !req.requiresTerms;
  bool acceptMode = !req.requiresModeConsent;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: TruLuraGlassCard(
          paletteMode: TruLuraMode.aura,
          radius: 26,
          padding: const EdgeInsets.all(16),
          depth: true,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you enter ${req.mode.label}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: p.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This space is higher-intent. We use explicit consent to reduce harm, scams, and unwanted exposure.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  if (req.requiresTerms)
                    _ConsentRow(
                      value: acceptTerms,
                      onChanged: (v) => setSheetState(() => acceptTerms = v),
                      title: 'I agree to the Terms of Service',
                      subtitle: 'Required to access higher-risk environments.',
                    ),
                  if (req.requiresModeConsent)
                    _ConsentRow(
                      value: acceptMode,
                      onChanged: (v) => setSheetState(() => acceptMode = v),
                      title: 'I confirm I want to enter ${req.mode.label}',
                      subtitle: 'Consent-first. You can switch modes anytime.',
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Not now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: (acceptTerms && acceptMode)
                              ? () async {
                                  if (req.requiresTerms) await compliance.acceptTerms();
                                  if (req.requiresModeConsent) await compliance.acceptModeConsent(req.mode);
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop(true);
                                }
                              : null,
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
  return result ?? false;
}


class ExperienceModeCard extends StatelessWidget {
  final TruExperienceMode mode;

  const ExperienceModeCard({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExperienceModeController>();
    final app = context.watch<AppProvider>();
    final state = ctrl.stateOf(mode);
    final lock = ctrl.lockFor(mode);
    final perms = ctrl.permissionsFor(mode);
    final p = kTruLuraPalettes[TruLuraMode.aura]!;

    final participation = ctrl.participationOf(mode);
    final isLocked = participation == TruModeParticipationState.restricted;
    final isActive = participation == TruModeParticipationState.active;
    final isOn = participation == TruModeParticipationState.active || participation == TruModeParticipationState.passive;
    final canToggle = !isLocked && (mode.canDisable || !isOn);

    final Color accent = _accentFor(mode);
    final Color accent2 = _accentFor(mode, secondary: true);

    return TruLuraGlassCard(
      paletteMode: TruLuraMode.aura,
      depth: true,
      padding: const EdgeInsets.all(14),
      fillAOverride: Colors.white.withValues(alpha: isOn ? 0.08 : 0.06),
      fillBOverride: Colors.white.withValues(alpha: isOn ? 0.06 : 0.04),
      borderColorOverride: isOn ? accent.withValues(alpha: 0.35) : p.border,
      glow: isActive ? accent2 : (isOn ? accent2.withValues(alpha: 0.6) : null),
      onTap: isLocked
          ? null
          : () async {
              if (!context.mounted) return;
              // Primary interaction: make it active.
              if (isActive) return;

              final req = await ComplianceService().requirementForMode(mode);
              if (!context.mounted) return;
              if (req != null) {
                final ok = await _showComplianceSheet(context, req);
                if (!context.mounted) return;
                if (!ok) return;
              }

              final decision = ctrl.transitionTo(mode);
              if (decision.type == TruModeTransitionType.blocked) {
                await _showInfoSheet(context, title: 'Can’t switch', message: decision.reason ?? 'This transition is blocked by safety rules.');
                return;
              }
              if (decision.requiresConfirmation) {
                final ok = await _confirmTransition(context, title: 'Switch to ${mode.label}?', message: decision.reason ?? 'This changes your intent context.');
                if (!context.mounted) return;
                if (!ok) return;
                await ctrl.setActiveMode(mode, confirmed: true);
                return;
              }
              if (decision.type == TruModeTransitionType.restricted) {
                // If restricted by transition but lock is not locked, allow. Otherwise show lock.
                if (ctrl.lockFor(mode).locked) {
                  await _showInfoSheet(context, title: 'Mode locked', message: decision.reason ?? 'This mode is locked.');
                  return;
                }
              }
              await ctrl.setActiveMode(mode);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeIcon(glyph: mode.glyph, accent: accent2, active: isOn && !isLocked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mode.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: p.text,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ),
                        if (isLocked)
                          const TruluraStatusBadge(
                            label: 'Locked',
                            tone: TruluraStatusTone.warning,
                          )
                        else if (isActive)
                          const TruluraStatusBadge(
                            label: 'Active',
                            tone: TruluraStatusTone.success,
                          )
                        else if (isOn)
                          const TruluraStatusBadge(
                            label: 'Passive',
                            tone: TruluraStatusTone.neutral,
                          )
                        else
                          const TruluraStatusBadge(
                            label: 'Off',
                            tone: TruluraStatusTone.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode.tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (mode == TruExperienceMode.luxe)
                _LuxeAccessButton(
                  unlocked: !isLocked,
                  onPressed: () async {
                    if (isLocked) {
                      await _showInfoSheet(
                        context,
                        title: 'Luxe access',
                        message:
                            '${lock.reason ?? 'Luxe is gated.'} Luxe requires an approved invite, an active membership, and advanced verification before controls unlock.',
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    await ctrl.setActiveMode(mode);
                  },
                )
              else
                Opacity(
                  opacity: canToggle ? 1.0 : 0.55,
                  child: TruToggle(
                    value: state.isEnabled,
                    onChanged: canToggle
                        ? (v) async {
                            await ctrl.setEnabled(mode, v);
                            if (!context.mounted) return;
                            if (v && ctrl.activeMode == TruExperienceMode.social && mode != TruExperienceMode.social) {
                              await ctrl.setActiveMode(mode);
                            }
                          }
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _permissionChips(context, perms, p: p, accent: accent),
          ),
          if (isLocked && lock.reason != null) ...[
            const SizedBox(height: 12),
            _LockReasonRow(
              reason: lock.reason!,
              actionLabel: lock.actionLabel,
              onAction: () => _handleLockAction(
                context,
                actionLabel: lock.actionLabel,
                mode: mode,
              ),
            ),
          ],
          if (mode == TruExperienceMode.creator && !isLocked) ...[
            const SizedBox(height: 12),
            _LockReasonRow(
              reason: app.creatorApproved
                  ? 'Creator onboarding and approval are complete. TruStudio tools can stay available alongside normal social posting.'
                  : 'Basic posting can stay social-first. TruStudio tools still depend on creator approval.',
              actionLabel: app.creatorApproved ? null : 'Verify',
              onAction: () => _handleLockAction(
                context,
                actionLabel: app.creatorApproved ? null : 'Verify',
                mode: mode,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VisibilityPill(
                  value: state.visibility,
                    enabled: isOn && !isLocked,
                  onChanged: (v) => ctrl.setVisibility(mode, v),
                ),
              ),
              const SizedBox(width: 10),
              if (!mode.canDisable)
                Text('Always on', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.muted))
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLockAction(
    BuildContext context, {
    required String? actionLabel,
    required TruExperienceMode mode,
  }) {
    if (actionLabel == 'Verify') {
      context.push(
        Uri(
          path: AppRoutes.safetyVerification,
          queryParameters: {
            'returnTo': GoRouterState.of(context).uri.toString(),
          },
        ).toString(),
      );
      return;
    }
    if (actionLabel == 'Onboarding') {
      context.push(
        Uri(
          path: AppRoutes.safetyVerification,
          queryParameters: {
            'returnTo': GoRouterState.of(context).uri.toString(),
          },
        ).toString(),
      );
      return;
    }
    final message = switch (mode) {
      TruExperienceMode.luxe =>
        'Luxe stays visible, but it remains locked until invite, membership, and advanced verification are all complete.',
      TruExperienceMode.creator =>
        'Complete creator onboarding first, then approval can unlock advanced creator tools.',
      _ => 'This mode is locked right now.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Widget> _permissionChips(BuildContext context, ModePermissions perms, {required TruLuraPalette p, required Color accent}) {
    final items = <_PermChipData>[
      _PermChipData('Message', perms.messaging),
      _PermChipData('Match', perms.matching),
      _PermChipData('Monetize', perms.monetization),
      _PermChipData('Anonymous', perms.anonymousUse),
      _PermChipData('Groups', perms.groups),
      _PermChipData('Live', perms.live),
      _PermChipData('Events', perms.events),
      _PermChipData(perms.feedKind.label, TruPermissionLevel.limited),
    ];

    return items.map((i) {
      final level = i.level;
      final bool on = level == TruPermissionLevel.allowed;
      final bool limited = level == TruPermissionLevel.limited;
      final Color bg = on
          ? accent.withValues(alpha: 0.14)
          : limited
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05);
      final Color border = on
          ? Colors.white.withValues(alpha: 0.14)
          : limited
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.08);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: bg, border: Border.all(color: border)),
        child: Text(
          '${level.glyph} ${i.label}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: on ? TruLuraTokens.textPrimary : p.muted,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
        ),
      );
    }).toList();
  }

  Future<bool> _confirmTransition(BuildContext context, {required String title, required String message}) async {
    final p = kTruLuraPalettes[TruLuraMode.aura]!;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: TruLuraGlassCard(
          paletteMode: TruLuraMode.aura,
          depth: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: p.text, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: p.muted, height: 1.4)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
                      ),
                      child: Text('Not now', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(color: p.muted, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: TruLuraTokens.auraViolet.withValues(alpha: 0.20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: TruLuraTokens.auraViolet.withValues(alpha: 0.28))),
                      ),
                      child: Text('Switch', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(color: TruLuraTokens.textPrimary, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _showInfoSheet(BuildContext context, {required String title, required String message}) async {
    final p = kTruLuraPalettes[TruLuraMode.aura]!;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: TruLuraGlassCard(
          paletteMode: TruLuraMode.aura,
          depth: true,
          radius: 26,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: p.text, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: p.muted, height: 1.4)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                  ),
                  child: Text('Okay', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(color: TruLuraTokens.textPrimary, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentFor(TruExperienceMode mode, {bool secondary = false}) {
    switch (mode) {
      case TruExperienceMode.social:
        return secondary ? TruLuraTokens.auraCyan : TruLuraTokens.auraViolet;
      case TruExperienceMode.friendship:
        return secondary ? TruLuraTokens.auraPink : TruLuraTokens.auraViolet;
      case TruExperienceMode.dating:
        return secondary ? TruLuraTokens.auraPink : TruLuraTokens.auraViolet;
      case TruExperienceMode.vent:
        return secondary ? TruLuraTokens.auraCyan : TruLuraTokens.deepIndigo;
      case TruExperienceMode.creator:
        return secondary ? TruLuraTokens.auraPink : TruLuraTokens.auraCyan;
      case TruExperienceMode.youth:
        return secondary ? TruLuraTokens.auraCyan : TruLuraTokens.auraViolet;
      case TruExperienceMode.luxe:
        return secondary ? const Color(0xFFE8C76B) : const Color(0xFFB8922C);
      case TruExperienceMode.altIntimate:
        return secondary ? TruLuraTokens.auraPink : TruLuraTokens.deepIndigo;
    }
  }
}

class _ConsentRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TruToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LuxeAccessButton extends StatelessWidget {
  final bool unlocked;
  final VoidCallback onPressed;

  const _LuxeAccessButton({
    required this.unlocked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: const Color(0xFFB8922C).withValues(alpha: unlocked ? 0.16 : 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: const Color(0xFFE8C76B).withValues(alpha: 0.28)),
        ),
      ),
        child: Text(
        unlocked ? 'Luxe controls' : 'Locked',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: TruLuraTokens.textPrimary,
                fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _PermChipData {
  final String label;
  final TruPermissionLevel level;
  const _PermChipData(this.label, this.level);
}

class _ModeIcon extends StatelessWidget {
  final TruLuraGlyph glyph;
  final Color accent;
  final bool active;

  const _ModeIcon({required this.glyph, required this.accent, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TruLuraTokens.auraViolet.withValues(alpha: 0.38),
                  accent.withValues(alpha: 0.26),
                ],
              )
            : null,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: active ? TruLuraTokens.softGlow(accent) : null,
      ),
      child: Center(
        child: TruLuraIcon(
          glyph: glyph,
          size: 22,
          active: active,
          color: TruLuraTokens.textPrimary,
        ),
      ),
    );
  }
}

class _VisibilityPill extends StatelessWidget {
  final TruVisibilityLevel value;
  final bool enabled;
  final ValueChanged<TruVisibilityLevel> onChanged;

  const _VisibilityPill({required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[TruLuraMode.aura]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TruLuraIcon(glyph: TruLuraGlyph.search, size: 18, active: enabled, color: p.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Visibility',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.muted, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<TruVisibilityLevel>(
              value: value,
              onChanged: enabled ? (v) => v == null ? null : onChanged(v) : null,
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: TruVisibilityLevel.values
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TruLuraTokens.textPrimary)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockReasonRow extends StatelessWidget {
  final String reason;
  final String? actionLabel;
  final VoidCallback onAction;

  const _LockReasonRow({required this.reason, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[TruLuraMode.aura]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: TruLuraTokens.auraPink.withValues(alpha: 0.08),
        border: Border.all(color: TruLuraTokens.auraPink.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          TruLuraIcon(glyph: TruLuraGlyph.lock, size: 18, active: true, color: TruLuraTokens.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(reason, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.text.withValues(alpha: 0.92), height: 1.25)),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              ),
              child: Text(actionLabel!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TruLuraTokens.textPrimary, fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeSkeleton extends StatelessWidget {
  const _ModeSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruLuraGlassCard(
      paletteMode: TruLuraMode.aura,
      depth: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 160, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),
          Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 8),
          Container(height: 12, width: 240, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }
}
