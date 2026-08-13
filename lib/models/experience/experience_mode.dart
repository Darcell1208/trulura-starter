import 'package:flutter/foundation.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Participation/experience modes.
///
/// This is intentionally separate from [TruLuraMode] (visual palette modes).
/// Experience modes govern *product behavior* and feature access.
enum TruExperienceMode {
  social,
  friendship,
  dating,
  vent,
  creator,
  youth,
  luxe,
  altIntimate,
}

/// Which participation layer a mode is currently in.
enum TruModeParticipationState { active, passive, off, restricted }

/// High-level feed behavior label used by UI.
enum TruFeedKind { social, platonic, romantic, emotional, content, filtered, curated, private }

/// Primary intent context for interaction behavior.
///
/// This is used to prevent cross-mode behavior violations (e.g. romantic actions
/// in a platonic context) even if multiple modes are enabled.
enum TruInteractionContext { social, platonic, romantic, support, creator, youth, luxe, alternative }

extension TruInteractionContextX on TruInteractionContext {
  String get label {
    switch (this) {
      case TruInteractionContext.social:
        return 'Social';
      case TruInteractionContext.platonic:
        return 'Platonic';
      case TruInteractionContext.romantic:
        return 'Romantic';
      case TruInteractionContext.support:
        return 'Support';
      case TruInteractionContext.creator:
        return 'Creator';
      case TruInteractionContext.youth:
        return 'Youth';
      case TruInteractionContext.luxe:
        return 'Luxe';
      case TruInteractionContext.alternative:
        return 'Alternative';
    }
  }
}

extension TruFeedKindX on TruFeedKind {
  String get label {
    switch (this) {
      case TruFeedKind.social:
        return 'Social';
      case TruFeedKind.platonic:
        return 'Platonic';
      case TruFeedKind.romantic:
        return 'Romantic';
      case TruFeedKind.emotional:
        return 'Emotional';
      case TruFeedKind.content:
        return 'Content';
      case TruFeedKind.filtered:
        return 'Filtered';
      case TruFeedKind.curated:
        return 'Curated';
      case TruFeedKind.private:
        return 'Private';
    }
  }
}

enum TruVisibilityLevel { public, limited, hidden }

extension TruVisibilityLevelX on TruVisibilityLevel {
  static TruVisibilityLevel? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruVisibilityLevel.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruVisibilityLevel.public:
        return 'Public';
      case TruVisibilityLevel.limited:
        return 'Limited';
      case TruVisibilityLevel.hidden:
        return 'Hidden';
    }
  }
}

@immutable
class ExperienceModeState {
  final TruExperienceMode mode;
  final bool isEnabled;
  final TruVisibilityLevel visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExperienceModeState({
    required this.mode,
    required this.isEnabled,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'isEnabled': isEnabled,
        'visibility': visibility.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ExperienceModeState.fromJson(Map<String, dynamic> json) {
    final mode = TruExperienceModeX.tryParse(json['mode'] as String?) ?? TruExperienceMode.social;
    final now = DateTime.now();
    return ExperienceModeState(
      mode: mode,
      isEnabled: (json['isEnabled'] as bool?) ?? (mode == TruExperienceMode.social),
      visibility: TruVisibilityLevelX.tryParse(json['visibility'] as String?) ?? TruVisibilityLevel.public,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? now,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? now,
    );
  }

  ExperienceModeState copyWith({bool? isEnabled, TruVisibilityLevel? visibility, DateTime? updatedAt}) => ExperienceModeState(
        mode: mode,
        isEnabled: isEnabled ?? this.isEnabled,
        visibility: visibility ?? this.visibility,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

@immutable
class ModePermissions {
  final TruPermissionLevel messaging;
  final TruPermissionLevel matching;
  final TruPermissionLevel monetization;
  final TruPermissionLevel anonymousUse;
  final TruFeedKind feedKind;

  /// Intent context for UI + enforcement.
  final TruInteractionContext interaction;

  /// Whether romantic escalation pathways are allowed to appear.
  ///
  /// Example: Friendship mode keeps romantic actions suppressed.
  final bool allowRomanticEscalation;

  /// Whether virality / ranking / growth incentives should be suppressed.
  ///
  /// This is critical for Vent/Support.
  final bool suppressVirality;

  // Additional v1 flags (kept for existing UI chips).
  final TruPermissionLevel groups;
  final TruPermissionLevel live;
  final TruPermissionLevel events;

  const ModePermissions({
    required this.messaging,
    required this.matching,
    required this.monetization,
    required this.anonymousUse,
    required this.feedKind,
    required this.interaction,
    required this.allowRomanticEscalation,
    required this.suppressVirality,
    required this.groups,
    required this.live,
    required this.events,
  });
}

/// A single derived “participation context” used to reconfigure the app.
///
/// - Active mode determines *primary* intent + UI.
/// - Passive modes can enable background layers (e.g. Creator monetization)
///   without overriding protected contexts like Vent.
@immutable
class TruParticipationContext {
  final TruExperienceMode activeMode;
  final List<TruExperienceMode> passiveModes;
  final List<TruExperienceMode> restrictedModes;
  final ModePermissions activePermissions;
  final ModePermissions effectivePermissions;

  const TruParticipationContext({
    required this.activeMode,
    required this.passiveModes,
    required this.restrictedModes,
    required this.activePermissions,
    required this.effectivePermissions,
  });

  bool get isProtectedEmotionalSpace => activeMode == TruExperienceMode.vent;
  bool get isYouthContext => activeMode == TruExperienceMode.youth;
}

enum TruPermissionLevel { allowed, limited, blocked }

extension TruPermissionLevelX on TruPermissionLevel {
  String get glyph {
    switch (this) {
      case TruPermissionLevel.allowed:
        return '✔';
      case TruPermissionLevel.limited:
        return '◐';
      case TruPermissionLevel.blocked:
        return '✖';
    }
  }

  String get label {
    switch (this) {
      case TruPermissionLevel.allowed:
        return 'Allowed';
      case TruPermissionLevel.limited:
        return 'Limited';
      case TruPermissionLevel.blocked:
        return 'Blocked';
    }
  }
}

@immutable
class ModeLock {
  final bool locked;
  final String? reason;
  final String? actionLabel;

  const ModeLock({required this.locked, this.reason, this.actionLabel});

  const ModeLock.unlocked() : locked = false, reason = null, actionLabel = null;
}

/// Defines how switching from one mode to another should behave.
enum TruModeTransitionType { soft, guarded, restricted, blocked }

@immutable
class TruModeTransitionDecision {
  final TruModeTransitionType type;
  final String? reason;

  const TruModeTransitionDecision({required this.type, this.reason});

  bool get requiresConfirmation => type == TruModeTransitionType.guarded;
  bool get isAllowed => type != TruModeTransitionType.blocked;
}

extension TruExperienceModeX on TruExperienceMode {
  static TruExperienceMode? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruExperienceMode.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruExperienceMode.social:
        return 'Social';
      case TruExperienceMode.friendship:
        return 'Friendship';
      case TruExperienceMode.dating:
        return 'Dating';
      case TruExperienceMode.vent:
        return 'Vent';
      case TruExperienceMode.creator:
        return 'Creator';
      case TruExperienceMode.youth:
        return 'Youth';
      case TruExperienceMode.luxe:
        return 'Luxe';
      case TruExperienceMode.altIntimate:
        return 'Alt / Intimate';
    }
  }

  String get tagline {
    switch (this) {
      case TruExperienceMode.social:
        return 'The default world — share, explore, and connect.';
      case TruExperienceMode.friendship:
        return 'Warm, platonic discovery. Low pressure.';
      case TruExperienceMode.dating:
        return 'Intentional romance — only when you choose it.';
      case TruExperienceMode.vent:
        return 'Protected expression. Soft, private, supported.';
      case TruExperienceMode.creator:
        return 'Publish, grow, and monetize — safety-first.';
      case TruExperienceMode.youth:
        return 'Isolated, age-appropriate participation.';
      case TruExperienceMode.luxe:
        return 'Discreet, curated visibility with elevated privacy.';
      case TruExperienceMode.altIntimate:
        return 'Consensual, gated, and clearly separated.';
    }
  }

  TruLuraGlyph get glyph {
    switch (this) {
      case TruExperienceMode.social:
        return TruLuraGlyph.aura;
      case TruExperienceMode.friendship:
        return TruLuraGlyph.heartOutline;
      case TruExperienceMode.dating:
        return TruLuraGlyph.spark;
      case TruExperienceMode.vent:
        return TruLuraGlyph.moon;
      case TruExperienceMode.creator:
        return TruLuraGlyph.star;
      case TruExperienceMode.youth:
        return TruLuraGlyph.cake;
      case TruExperienceMode.luxe:
        return TruLuraGlyph.lock;
      case TruExperienceMode.altIntimate:
        return TruLuraGlyph.shield;
    }
  }

  /// Default permissions for the mode (v1 scaffolding).
  ModePermissions basePermissions() {
    // This is the baseline matrix from the spec. Dynamic gating is applied in
    // [TruExperienceModePolicy.permissionsFor].
    switch (this) {
      case TruExperienceMode.social:
        return const ModePermissions(
          messaging: TruPermissionLevel.allowed,
          matching: TruPermissionLevel.blocked,
          monetization: TruPermissionLevel.limited,
          anonymousUse: TruPermissionLevel.limited,
          feedKind: TruFeedKind.social,
          interaction: TruInteractionContext.social,
          allowRomanticEscalation: false,
          suppressVirality: false,
          groups: TruPermissionLevel.allowed,
          live: TruPermissionLevel.allowed,
          events: TruPermissionLevel.allowed,
        );
      case TruExperienceMode.dating:
        return const ModePermissions(
          messaging: TruPermissionLevel.allowed,
          matching: TruPermissionLevel.allowed,
          monetization: TruPermissionLevel.allowed,
          anonymousUse: TruPermissionLevel.limited,
          feedKind: TruFeedKind.romantic,
          interaction: TruInteractionContext.romantic,
          allowRomanticEscalation: true,
          suppressVirality: false,
          groups: TruPermissionLevel.blocked,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.blocked,
        );
      case TruExperienceMode.friendship:
        return const ModePermissions(
          messaging: TruPermissionLevel.allowed,
          matching: TruPermissionLevel.allowed,
          monetization: TruPermissionLevel.blocked,
          anonymousUse: TruPermissionLevel.limited,
          feedKind: TruFeedKind.platonic,
          interaction: TruInteractionContext.platonic,
          allowRomanticEscalation: false,
          suppressVirality: false,
          groups: TruPermissionLevel.allowed,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.allowed,
        );
      case TruExperienceMode.vent:
        return const ModePermissions(
          messaging: TruPermissionLevel.limited,
          matching: TruPermissionLevel.blocked,
          monetization: TruPermissionLevel.blocked,
          anonymousUse: TruPermissionLevel.allowed,
          feedKind: TruFeedKind.emotional,
          interaction: TruInteractionContext.support,
          allowRomanticEscalation: false,
          suppressVirality: true,
          groups: TruPermissionLevel.limited,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.blocked,
        );
      case TruExperienceMode.creator:
        return const ModePermissions(
          messaging: TruPermissionLevel.allowed,
          matching: TruPermissionLevel.blocked,
          monetization: TruPermissionLevel.allowed,
          anonymousUse: TruPermissionLevel.limited,
          feedKind: TruFeedKind.content,
          interaction: TruInteractionContext.creator,
          allowRomanticEscalation: false,
          suppressVirality: false,
          groups: TruPermissionLevel.allowed,
          live: TruPermissionLevel.allowed,
          events: TruPermissionLevel.allowed,
        );
      case TruExperienceMode.youth:
        return const ModePermissions(
          messaging: TruPermissionLevel.limited,
          matching: TruPermissionLevel.blocked,
          monetization: TruPermissionLevel.blocked,
          anonymousUse: TruPermissionLevel.limited,
          feedKind: TruFeedKind.filtered,
          interaction: TruInteractionContext.youth,
          allowRomanticEscalation: false,
          suppressVirality: true,
          groups: TruPermissionLevel.allowed,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.limited,
        );
      case TruExperienceMode.luxe:
        return const ModePermissions(
          messaging: TruPermissionLevel.allowed,
          matching: TruPermissionLevel.allowed,
          monetization: TruPermissionLevel.allowed,
          anonymousUse: TruPermissionLevel.allowed,
          feedKind: TruFeedKind.curated,
          interaction: TruInteractionContext.luxe,
          allowRomanticEscalation: true,
          suppressVirality: false,
          groups: TruPermissionLevel.blocked,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.allowed,
        );
      case TruExperienceMode.altIntimate:
        return const ModePermissions(
          messaging: TruPermissionLevel.allowed,
          matching: TruPermissionLevel.allowed,
          monetization: TruPermissionLevel.allowed,
          anonymousUse: TruPermissionLevel.allowed,
          feedKind: TruFeedKind.private,
          interaction: TruInteractionContext.alternative,
          allowRomanticEscalation: true,
          suppressVirality: true,
          groups: TruPermissionLevel.blocked,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.blocked,
        );
    }
  }

  /// Whether the mode represents an adult-intent environment.
  bool get isAdultIntent => this == TruExperienceMode.dating || this == TruExperienceMode.altIntimate || this == TruExperienceMode.luxe;

  /// Whether this mode is a protected emotional space.
  bool get isProtectedSpace => this == TruExperienceMode.vent;

  TruModeTransitionDecision transitionFrom({required TruExperienceMode from, required User? user, required bool creatorApproved}) {
    if (from == this) return const TruModeTransitionDecision(type: TruModeTransitionType.soft);

    // Hard safety boundaries.
    if (user != null && user.age < 18) {
      if (from == TruExperienceMode.youth && (this == TruExperienceMode.altIntimate || this == TruExperienceMode.dating || this == TruExperienceMode.luxe)) {
        return const TruModeTransitionDecision(type: TruModeTransitionType.blocked, reason: 'Youth users can’t enter adult modes.');
      }
    }

    // Guarded transitions (confirmation).
    final guardedPairs = <(TruExperienceMode, TruExperienceMode)>{
      (TruExperienceMode.social, TruExperienceMode.dating),
      (TruExperienceMode.social, TruExperienceMode.altIntimate),
      (TruExperienceMode.friendship, TruExperienceMode.dating),
      (TruExperienceMode.social, TruExperienceMode.luxe),
      (TruExperienceMode.dating, TruExperienceMode.luxe),
    };
    if (guardedPairs.contains((from, this))) {
      return const TruModeTransitionDecision(type: TruModeTransitionType.guarded, reason: 'This shift changes the intent context. Confirm you want to switch.');
    }

    return const TruModeTransitionDecision(type: TruModeTransitionType.soft);
  }

  /// Whether this mode can be disabled.
  ///
  /// We keep Social always-available (and effectively required) so users never
  /// end up with a "dead" account state.
  bool get canDisable => this != TruExperienceMode.social;

  /// Mutual exclusion groups (v1).
  bool get isYouth => this == TruExperienceMode.youth;

  ModeLock lockStatus({
    required User? user,
    required bool creatorOnboardingComplete,
    required bool creatorApproved,
    required bool hasAdvancedVerification,
    required bool hasLuxeInvite,
    required bool hasLuxeSubscription,
  }) {
    // No user => we don't lock (pre-auth exploration can still show UI).
    if (user == null) return const ModeLock.unlocked();

    // Safety gating: high-risk accounts get restricted.
    if (user.riskLevel == TruRiskLevel.high) {
      // Vent is still allowed, but other modes get restricted.
      if (this != TruExperienceMode.vent) {
        return const ModeLock(locked: true, reason: 'Temporarily restricted by safety review.', actionLabel: 'Review');
      }
    }

    switch (this) {
      case TruExperienceMode.social:
        return const ModeLock.unlocked();
      case TruExperienceMode.friendship:
        return const ModeLock.unlocked();
      case TruExperienceMode.vent:
        return const ModeLock.unlocked();
      case TruExperienceMode.creator:
        return const ModeLock.unlocked();
      case TruExperienceMode.dating:
        if (user.age < 18) {
          return const ModeLock(locked: true, reason: 'Dating requires 18+.', actionLabel: 'Learn');
        }
        // Optional: require at least level1 for Dating.
        if (user.verificationLevel == TruVerificationLevel.level0) {
          return const ModeLock(locked: true, reason: 'Dating unlocks after basic verification.', actionLabel: 'Verify');
        }
        return const ModeLock.unlocked();
      case TruExperienceMode.youth:
        if (user.age >= 18) {
          return const ModeLock(locked: true, reason: 'Youth mode is for teens.', actionLabel: 'Learn');
        }
        return const ModeLock.unlocked();
      case TruExperienceMode.luxe:
        if (!hasLuxeInvite) {
          return const ModeLock(
            locked: true,
            reason: 'Invite required.',
            actionLabel: 'Invite',
          );
        }
        if (!hasLuxeSubscription) {
          return const ModeLock(
            locked: true,
            reason: 'Membership required.',
            actionLabel: 'Upgrade',
          );
        }
        if (!hasAdvancedVerification ||
            user.verificationLevel.index < TruVerificationLevel.level2.index) {
          return const ModeLock(
            locked: true,
            reason: 'Verification required.',
            actionLabel: 'Verify',
          );
        }
        return const ModeLock.unlocked();
      case TruExperienceMode.altIntimate:
        if (user.age < 18) {
          return const ModeLock(locked: true, reason: 'Alt/Intimate requires 18+.', actionLabel: 'Learn');
        }
        if (user.verificationLevel.index < TruVerificationLevel.level3.index) {
          return const ModeLock(locked: true, reason: 'This mode requires trusted verification.', actionLabel: 'Verify');
        }
        return const ModeLock.unlocked();
    }
  }
}

/// Central policy engine:
/// - derives dynamic permissions from (mode + user trust/verification)
/// - provides a single place to add future server-backed trust scoring
class TruExperienceModePolicy {
  static ModePermissions permissionsFor({
    required TruExperienceMode mode,
    required User? user,
    required bool creatorOnboardingComplete,
    required bool creatorApproved,
    required bool hasAdvancedVerification,
    required bool hasLuxeInvite,
    required bool hasLuxeSubscription,
  }) {
    final base = mode.basePermissions();
    if (user == null) return base;

    // Trust/safety moderation: high risk suppresses reach + high-intent actions.
    if (user.riskLevel == TruRiskLevel.high) {
      if (mode != TruExperienceMode.vent) {
        return ModePermissions(
          messaging: TruPermissionLevel.limited,
          matching: TruPermissionLevel.blocked,
          monetization: TruPermissionLevel.blocked,
          anonymousUse: base.anonymousUse,
          feedKind: base.feedKind,
          interaction: base.interaction,
          allowRomanticEscalation: false,
          suppressVirality: base.suppressVirality,
          groups: TruPermissionLevel.limited,
          live: TruPermissionLevel.blocked,
          events: TruPermissionLevel.blocked,
        );
      }
    }

    // Verification gating (example baseline):
    // - Dating requires level1 for matching
    // - Luxe requires level2 for matching + monetization
    // - Alt/Intimate requires level3 for matching
    final v = user.verificationLevel;
    if (mode == TruExperienceMode.creator &&
        (!creatorOnboardingComplete || !creatorApproved)) {
      return ModePermissions(
        messaging: base.messaging,
        matching: base.matching,
        monetization: TruPermissionLevel.blocked,
        anonymousUse: base.anonymousUse,
        feedKind: base.feedKind,
        interaction: base.interaction,
        allowRomanticEscalation: base.allowRomanticEscalation,
        suppressVirality: base.suppressVirality,
        groups: base.groups,
        live: TruPermissionLevel.blocked,
        events: base.events,
      );
    }
    if (mode == TruExperienceMode.dating && v == TruVerificationLevel.level0) {
      return ModePermissions(
        messaging: base.messaging,
        matching: TruPermissionLevel.blocked,
        monetization: base.monetization,
        anonymousUse: base.anonymousUse,
        feedKind: base.feedKind,
        interaction: base.interaction,
        allowRomanticEscalation: base.allowRomanticEscalation,
        suppressVirality: base.suppressVirality,
        groups: base.groups,
        live: base.live,
        events: base.events,
      );
    }
    if (mode == TruExperienceMode.luxe &&
        (!hasLuxeInvite ||
            !hasLuxeSubscription ||
            !hasAdvancedVerification ||
            v.index < TruVerificationLevel.level2.index)) {
      return ModePermissions(
        messaging: base.messaging,
        matching: TruPermissionLevel.blocked,
        monetization: TruPermissionLevel.blocked,
        anonymousUse: base.anonymousUse,
        feedKind: base.feedKind,
        interaction: base.interaction,
        allowRomanticEscalation: base.allowRomanticEscalation,
        suppressVirality: base.suppressVirality,
        groups: base.groups,
        live: base.live,
        events: base.events,
      );
    }
    if (mode == TruExperienceMode.altIntimate && v.index < TruVerificationLevel.level3.index) {
      return ModePermissions(
        messaging: base.messaging,
        matching: TruPermissionLevel.blocked,
        monetization: base.monetization,
        anonymousUse: base.anonymousUse,
        feedKind: base.feedKind,
        interaction: base.interaction,
        allowRomanticEscalation: base.allowRomanticEscalation,
        suppressVirality: base.suppressVirality,
        groups: base.groups,
        live: base.live,
        events: base.events,
      );
    }

    return base;
  }

  /// Computes a single effective permission set given the active + passive set.
  ///
  /// Rules (matching the spec):
  /// - Active mode defines the primary interaction context.
  /// - Vent/Support suppresses virality + monetization regardless of passive Creator.
  /// - Youth blocks adult-intent and monetization; passive adult modes must not leak.
  static ModePermissions effectivePermissions({required ModePermissions active, required List<ModePermissions> passive}) {
    if (active.suppressVirality) {
      // Protected contexts win over passive layers.
      return ModePermissions(
        messaging: active.messaging,
        matching: active.matching,
        monetization: TruPermissionLevel.blocked,
        anonymousUse: active.anonymousUse,
        feedKind: active.feedKind,
        interaction: active.interaction,
        allowRomanticEscalation: active.allowRomanticEscalation,
        suppressVirality: true,
        groups: active.groups,
        live: active.live,
        events: active.events,
      );
    }

    if (active.interaction == TruInteractionContext.youth) {
      return ModePermissions(
        messaging: active.messaging,
        matching: TruPermissionLevel.blocked,
        monetization: TruPermissionLevel.blocked,
        anonymousUse: active.anonymousUse,
        feedKind: active.feedKind,
        interaction: active.interaction,
        allowRomanticEscalation: false,
        suppressVirality: true,
        groups: active.groups,
        live: active.live,
        events: active.events,
      );
    }

    // Soft union: allow creator monetization layer if present AND active mode allows it.
    final hasCreatorLayer = passive.any((p) => p.interaction == TruInteractionContext.creator && p.monetization == TruPermissionLevel.allowed);
    final monetization = hasCreatorLayer && active.monetization != TruPermissionLevel.blocked ? TruPermissionLevel.allowed : active.monetization;

    return ModePermissions(
      messaging: active.messaging,
      matching: active.matching,
      monetization: monetization,
      anonymousUse: active.anonymousUse,
      feedKind: active.feedKind,
      interaction: active.interaction,
      allowRomanticEscalation: active.allowRomanticEscalation,
      suppressVirality: active.suppressVirality,
      groups: active.groups,
      live: active.live,
      events: active.events,
    );
  }
}
