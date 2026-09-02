import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/identity/identity_core.dart';
import 'package:trulura/models/identity/identity_profile.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/services/identity_core_repository.dart';
import 'package:trulura/services/identity_profile_service.dart';
import 'package:trulura/services/identity_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_segmented_pill.dart';
import 'package:trulura/widgets/tru_toggle.dart';

class IdentityCoreScreen extends StatefulWidget {
  const IdentityCoreScreen({super.key});

  @override
  State<IdentityCoreScreen> createState() => _IdentityCoreScreenState();
}

class _IdentityCoreScreenState extends State<IdentityCoreScreen> {
  final _users = UserService();
  final _identity = IdentityService();
  final _profiles = IdentityProfileService();
  final _identityCoreRepository = IdentityCoreRepository();
  final _communicationStyle = TextEditingController();
  final _coreValues = TextEditingController();
  final _relationshipPreferences = TextEditingController();

  User? _me;
  IdentityCore? _identityCore;
  List<TruIdentityProfile> _all = const [];
  bool _loading = true;
  bool _savingCore = false;
  TruIdentityMode? _activeMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await _users.getCurrentUser();
      final results = await Future.wait<Object?>([
        if (me == null)
          Future<List<TruIdentityProfile>>.value(const <TruIdentityProfile>[])
        else
          _profiles.getAll(userId: me.id),
        _identityCoreRepository.getForCurrentUser(),
      ]);
      final all = results[0] as List<TruIdentityProfile>;
      final identityCore = results[1] as IdentityCore?;
      if (!mounted) return;
      final editableCore =
          identityCore ?? (me == null ? null : IdentityCore.empty(me.id));
      _hydrateIdentityCoreFields(editableCore);
      setState(() {
        _me = me;
        _identityCore = editableCore;
        _all = all;
        _activeMode = me?.activeIdentityMode;
        _loading = false;
      });
    } catch (e) {
      debugPrint('IdentityCoreScreen load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _hydrateIdentityCoreFields(IdentityCore? identityCore) {
    _communicationStyle.text = identityCore?.communicationStyle ?? '';
    _coreValues.text = identityCore?.coreValues.join(', ') ?? '';
    _relationshipPreferences.text = identityCore?.relationshipPreferences ?? '';
  }

  List<String> _parseCoreValues(String raw) => raw
      .split(RegExp(r'[\n,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList(growable: false);

  String? _blankToNull(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _saveIdentityCore() async {
    final me = _me;
    final core = _identityCore;
    if (me == null && core == null) {
      _showSnack('Sign in to save your identity core.');
      return;
    }

    setState(() => _savingCore = true);
    try {
      final next = IdentityCore(
        userId: core?.userId ?? me!.id,
        communicationStyle: _blankToNull(_communicationStyle.text),
        coreValues: _parseCoreValues(_coreValues.text),
        relationshipPreferences: _blankToNull(_relationshipPreferences.text),
      );
      final saved = await _identityCoreRepository.save(next);
      if (!mounted) return;
      if (saved == null) {
        _showSnack('Could not save identity core. Try again when signed in.');
        return;
      }
      setState(() => _identityCore = saved);
      await context.read<AuraStateController>().initialize();
      if (!mounted) return;
      _showSnack('Identity core saved.');
    } finally {
      if (mounted) setState(() => _savingCore = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _communicationStyle.dispose();
    _coreValues.dispose();
    _relationshipPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final me = _me;
    final mode =
        _activeMode ?? me?.activeIdentityMode ?? TruIdentityMode.social;
    final anon = me?.anonymousOverlayEnabled ?? false;

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
        title: 'Identity Core',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            Text('Switch personas without switching accounts.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72), height: 1.4)),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Core signal',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _communicationStyle,
                    enabled: !_savingCore,
                    decoration: const InputDecoration(
                      labelText: 'Communication style',
                      hintText: 'Direct, playful, reflective...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _coreValues,
                    enabled: !_savingCore,
                    decoration: const InputDecoration(
                      labelText: 'Core values',
                      hintText: 'Kindness, honesty, curiosity',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _relationshipPreferences,
                    enabled: !_savingCore,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Relationship preferences',
                      hintText: 'What helps connection feel safe and real?',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _savingCore ? null : _saveIdentityCore,
                      child: Text(_savingCore ? 'Saving...' : 'Save core'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active layer',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  TruluraSegmentedPill(
                    options: const ['Social', 'Dating', 'Creator', 'Luxe'],
                    selectedIndex: [
                      mode == TruIdentityMode.social,
                      mode == TruIdentityMode.dating,
                      mode == TruIdentityMode.creator,
                      mode == TruIdentityMode.luxe
                    ].indexOf(true),
                    onChanged: (i) async {
                      final next = switch (i) {
                        0 => TruIdentityMode.social,
                        1 => TruIdentityMode.dating,
                        2 => TruIdentityMode.creator,
                        _ => TruIdentityMode.luxe
                      };
                      final lock = _lockFor(app, me, next);
                      if (lock != null) {
                        await _showGateSheet(context, next.label, lock);
                        return;
                      }
                      setState(() => _activeMode = next);
                      await _identity.setActiveMode(next);
                      await _load();
                    },
                    activeGradient:
                        TruLuraTokens.identityGradient(mode, opacity: 0.95),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Anonymous overlay',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text('Mask your name, handle, and profile details.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.70),
                                        height: 1.3)),
                          ],
                        ),
                      ),
                      TruToggle(
                        value: anon,
                        onChanged: (v) async {
                          await _identity.setAnonymousOverlay(v);
                          await _load();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (anon) const SizedBox(height: 14),
            if (anon)
              TruLuraGlassCard(
                radius: 24,
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Anonymous overlay is active. TruLura masks your visible name, softens profile identity details, and uses a persona label so you stay in control of what is revealed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.35),
                ),
              ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personas',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  for (final p
                      in _all.where((p) => p.mode != TruIdentityMode.vent)) ...[
                    (() {
                      final lock = _lockFor(app, me, p.mode);
                      return _PersonaRow(
                        profile: p,
                        selected: p.mode == mode,
                        lockedReason: lock?.reason,
                        lockedActionLabel: lock?.actionLabel,
                        onLockedTap: lock == null
                            ? null
                            : () => _showGateSheet(context, p.mode.label, lock),
                        onToggle: me == null || lock != null
                            ? null
                            : (v) async {
                                await _profiles.setModeActive(
                                    userId: me.id, mode: p.mode, active: v);
                                if (v) {
                                  setState(() => _activeMode = p.mode);
                                  await _identity.setActiveMode(p.mode);
                                }
                                await _load();
                              },
                        onEdit: me == null
                            ? null
                            : () => _editPersona(context, me.id, p),
                      );
                    })(),
                    const SizedBox(height: 10),
                  ],
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

  _PersonaLock? _lockFor(AppProvider app, User? me, TruIdentityMode mode) {
    switch (mode) {
      case TruIdentityMode.social:
      case TruIdentityMode.friendship:
        return null;
      case TruIdentityMode.dating:
        if ((me?.age ?? 18) < 18) {
          return const _PersonaLock(
            reason: 'Dating is only available for 18+ accounts.',
            actionLabel: 'Learn',
          );
        }
        if ((me?.verificationLevel ?? TruVerificationLevel.level0) ==
            TruVerificationLevel.level0) {
          return const _PersonaLock(
            reason: 'Dating becomes available after basic verification.',
            actionLabel: 'Verify',
          );
        }
        return null;
      case TruIdentityMode.creator:
        if (!app.creatorOnboardingComplete) {
          return const _PersonaLock(
            reason: 'Complete creator onboarding before this persona unlocks.',
            actionLabel: 'Onboarding',
          );
        }
        if (!app.creatorApproved) {
          return const _PersonaLock(
            reason:
                'Creator approval is still required for advanced creator spaces.',
            actionLabel: 'Verify',
          );
        }
        return null;
      case TruIdentityMode.luxe:
        if (!app.hasLuxeInvite) {
          return const _PersonaLock(
            reason: 'Invite required.',
            actionLabel: 'Invite',
          );
        }
        if (!app.hasLuxeSubscription) {
          return const _PersonaLock(
            reason: 'Membership required.',
            actionLabel: 'Upgrade',
          );
        }
        if (!app.hasAdvancedVerification ||
            (me?.verificationLevel.index ?? 0) <
                TruVerificationLevel.level2.index) {
          return const _PersonaLock(
            reason: 'Verification required.',
            actionLabel: 'Verify',
          );
        }
        return null;
      case TruIdentityMode.vent:
        return null;
    }
  }

  Future<void> _showGateSheet(
    BuildContext context,
    String label,
    _PersonaLock lock,
  ) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TruLuraGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label is gated',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  lock.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                if (lock.actionLabel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.push(
                          Uri(
                            path: AppRoutes.safetyVerification,
                            queryParameters: {
                              'returnTo':
                                  GoRouterState.of(context).uri.toString(),
                            },
                          ).toString(),
                        );
                      },
                      child: Text(lock.actionLabel!),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editPersona(
      BuildContext context, String userId, TruIdentityProfile profile) async {
    final display = TextEditingController(text: profile.displayName ?? '');
    final handle = TextEditingController(text: profile.username ?? '');
    final bio = TextEditingController(text: profile.bio ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: TruLuraGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit ${profile.mode.label} persona',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: display,
                  decoration: const InputDecoration(
                      labelText: 'Display name (optional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: handle,
                  decoration:
                      const InputDecoration(labelText: 'Username (optional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bio,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Bio (optional)'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(false),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: cs.onSurface),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true) return;
    final all = await _profiles.getAll(userId: userId);
    final next = all
        .map(
          (p) => p.mode == profile.mode
              ? p.copyWith(
                  displayName:
                      display.text.trim().isEmpty ? null : display.text.trim(),
                  username:
                      handle.text.trim().isEmpty ? null : handle.text.trim(),
                  bio: bio.text.trim().isEmpty ? null : bio.text.trim(),
                )
              : p,
        )
        .toList(growable: false);
    await _profiles.saveAll(userId: userId, profiles: next);
    await _load();
  }
}

class _PersonaRow extends StatelessWidget {
  final TruIdentityProfile profile;
  final bool selected;
  final String? lockedReason;
  final String? lockedActionLabel;
  final VoidCallback? onLockedTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEdit;

  const _PersonaRow({
    required this.profile,
    required this.selected,
    this.lockedReason,
    this.lockedActionLabel,
    this.onLockedTap,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLocked = lockedReason != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surfaceContainerHighest.withValues(
          alpha: isLocked ? 0.14 : (selected ? 0.26 : 0.18),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: selected ? 0.18 : 0.10),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(profile.mode.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w900))),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: TruLuraTokens.identityGradient(
                                profile.mode,
                                opacity: 0.9)),
                        child: Text('Active',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                      ),
                    ] else if (isLocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.28),
                        ),
                        child: Text(
                          lockedActionLabel ?? 'Locked',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isLocked
                      ? lockedReason!
                      : (profile.displayName?.trim().isNotEmpty ?? false) ||
                              (profile.username?.trim().isNotEmpty ?? false)
                          ? '${(profile.displayName ?? '').trim()} ${(profile.username ?? '').trim()}'
                          : 'Uses your base profile unless you override it.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70), height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded,
                color: cs.onSurface.withValues(alpha: 0.8)),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          if (isLocked)
            TextButton(
              onPressed: onLockedTap,
              child: Text(lockedActionLabel ?? 'Locked'),
            )
          else
            TruToggle(value: profile.isActive, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _PersonaLock {
  final String reason;
  final String? actionLabel;

  const _PersonaLock({required this.reason, this.actionLabel});
}
