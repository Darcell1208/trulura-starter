import 'package:flutter/foundation.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/experience_mode_service.dart';

/// In-memory controller for Experience Modes.
///
/// - Local-first persistence via [ExperienceModeService]
/// - Gating/locks are derived from the current cached [User] + app settings
/// - Designed so we can later swap persistence to Supabase/Firebase
class ExperienceModeController extends ChangeNotifier {
  final AppProvider _app;
  final ExperienceModeService _service;

  Map<TruExperienceMode, ExperienceModeState> _modes = const {};
  TruExperienceMode _activeMode = TruExperienceMode.social;
  bool _loading = false;

  ExperienceModeController({required AppProvider appProvider, ExperienceModeService? service})
      : _app = appProvider,
        _service = service ?? ExperienceModeService();

  bool get isLoading => _loading;

  Map<TruExperienceMode, ExperienceModeState> get modes => _modes;

  TruExperienceMode get activeMode => _activeMode;

  List<TruExperienceMode> get enabledModes => _modes.values.where((s) => s.isEnabled).map((s) => s.mode).toList();

  List<TruExperienceMode> get passiveModes => enabledModes.where((m) => m != _activeMode).toList(growable: false);

  ExperienceModeState stateOf(TruExperienceMode mode) => _modes[mode] ?? ExperienceModeState(mode: mode, isEnabled: mode == TruExperienceMode.social, visibility: TruVisibilityLevel.public, createdAt: DateTime.now(), updatedAt: DateTime.now());

  User? get _user => _app.currentUser;

  Future<void> initialize() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      _modes = await _service.getModes(userId: _user?.id);
      _activeMode = await _service.getActiveMode(userId: _user?.id);

      // Bridge v1 existing app toggles into the new system.
      if (_app.creatorModeEnabled) {
        _modes[TruExperienceMode.creator] = stateOf(TruExperienceMode.creator).copyWith(isEnabled: true, updatedAt: DateTime.now());
      }
      if (_app.fullSyncModeEnabled) {
        _modes[TruExperienceMode.dating] = stateOf(TruExperienceMode.dating).copyWith(isEnabled: true, updatedAt: DateTime.now());
      }

      await _service.setModes(_modes, userId: _user?.id);

      // Ensure active mode is actually enabled + available.
      if (!stateOf(_activeMode).isEnabled || lockFor(_activeMode).locked) {
        _activeMode = TruExperienceMode.social;
        await _service.setActiveMode(_activeMode, userId: _user?.id);
      }
    } catch (e) {
      debugPrint('ExperienceModeController.initialize failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ModeLock lockFor(TruExperienceMode mode) => mode.lockStatus(
        user: _user,
        creatorOnboardingComplete: _app.creatorOnboardingComplete,
        creatorApproved: _app.creatorApproved,
        hasAdvancedVerification: _app.hasAdvancedVerification,
        hasLuxeInvite: _app.hasLuxeInvite,
        hasLuxeSubscription: _app.hasLuxeSubscription,
      );

  ModePermissions permissionsFor(TruExperienceMode mode) =>
      TruExperienceModePolicy.permissionsFor(
        mode: mode,
        user: _user,
        creatorOnboardingComplete: _app.creatorOnboardingComplete,
        creatorApproved: _app.creatorApproved,
        hasAdvancedVerification: _app.hasAdvancedVerification,
        hasLuxeInvite: _app.hasLuxeInvite,
        hasLuxeSubscription: _app.hasLuxeSubscription,
      );

  TruParticipationContext get participationContext {
    final restricted = <TruExperienceMode>[];
    for (final m in TruExperienceMode.values) {
      if (participationOf(m) == TruModeParticipationState.restricted) restricted.add(m);
    }

    final activePerms = permissionsFor(_activeMode);
    final passivePerms = passiveModes.map(permissionsFor).toList(growable: false);
    final effective = TruExperienceModePolicy.effectivePermissions(active: activePerms, passive: passivePerms);

    return TruParticipationContext(
      activeMode: _activeMode,
      passiveModes: passiveModes,
      restrictedModes: restricted,
      activePermissions: activePerms,
      effectivePermissions: effective,
    );
  }

  TruModeParticipationState participationOf(TruExperienceMode mode) {
    final lock = lockFor(mode);
    final state = stateOf(mode);
    if (lock.locked) return TruModeParticipationState.restricted;
    if (mode == _activeMode) return TruModeParticipationState.active;
    if (state.isEnabled) return TruModeParticipationState.passive;
    return TruModeParticipationState.off;
  }

  TruModeTransitionDecision transitionTo(TruExperienceMode next) =>
      next.transitionFrom(
        from: _activeMode,
        user: _user,
        creatorApproved: _app.creatorApproved,
      );

  Future<bool> setActiveMode(TruExperienceMode next, {bool confirmed = false}) async {
    if (next == _activeMode) return true;

    final state = stateOf(next);
    if (!state.isEnabled) {
      // Allow auto-enabling when switching to it, as long as it's not locked.
      final lock = lockFor(next);
      if (lock.locked) return false;
      await setEnabled(next, true);
    }

    final decision = transitionTo(next);
    if (decision.type == TruModeTransitionType.blocked) return false;
    if (decision.requiresConfirmation && !confirmed) return false;

    // Restricted transition means it is allowed only if lock is not locked.
    final lock = lockFor(next);
    if (lock.locked) return false;

    _activeMode = next;
    notifyListeners();
    await _service.setActiveMode(_activeMode, userId: _user?.id);
    return true;
  }

  Future<void> setEnabled(TruExperienceMode mode, bool enabled) async {
    final current = stateOf(mode);
    if (current.isEnabled == enabled) return;

    // Social is always-on.
    if (!enabled && !mode.canDisable) return;

    final lock = lockFor(mode);
    if (enabled && lock.locked) return;

    final now = DateTime.now();

    // Mutual restriction: Youth cannot coexist with adult-intent modes.
    final next = Map<TruExperienceMode, ExperienceModeState>.from(_modes);
    if (enabled && mode == TruExperienceMode.youth) {
      for (final m in [TruExperienceMode.dating, TruExperienceMode.altIntimate, TruExperienceMode.luxe]) {
        next[m] = stateOf(m).copyWith(isEnabled: false, updatedAt: now);
      }
    }
    if (enabled && (mode == TruExperienceMode.dating || mode == TruExperienceMode.altIntimate || mode == TruExperienceMode.luxe)) {
      next[TruExperienceMode.youth] = stateOf(TruExperienceMode.youth).copyWith(isEnabled: false, updatedAt: now);
    }

    next[mode] = current.copyWith(isEnabled: enabled, updatedAt: now);
    // Ensure at least Social remains.
    next[TruExperienceMode.social] = stateOf(TruExperienceMode.social).copyWith(isEnabled: true, updatedAt: now);

    _modes = next;
    notifyListeners();
    await _service.setModes(_modes, userId: _user?.id);

    // If the active mode was turned off, fall back.
    if (!enabled && mode == _activeMode) {
      _activeMode = TruExperienceMode.social;
      notifyListeners();
      await _service.setActiveMode(_activeMode, userId: _user?.id);
    }

    // Bridge to existing app toggles.
    if (mode == TruExperienceMode.creator) {
      await _app.setCreatorModeEnabled(enabled);
      if (enabled && !_app.creatorApproved) {
        // Keep creator enabled but still "locked" tools; approval is separate.
      }
    }
    if (mode == TruExperienceMode.dating) {
      // Dating-enabled implies dating intent, but do NOT force dating-only.
      if (enabled) {
        await _app.setUseMode('both');
      }
    }
  }

  Future<void> setVisibility(TruExperienceMode mode, TruVisibilityLevel visibility) async {
    final current = stateOf(mode);
    final next = Map<TruExperienceMode, ExperienceModeState>.from(_modes);
    next[mode] = current.copyWith(visibility: visibility, updatedAt: DateTime.now());
    _modes = next;
    notifyListeners();
    await _service.setModes(_modes, userId: _user?.id);
  }
}
