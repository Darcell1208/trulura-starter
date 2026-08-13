import 'package:flutter/foundation.dart';

/// Matchmaking / Sync domain models.
///
/// These are local-first models that can be stored in SharedPreferences
/// (or swapped to Supabase/Firebase later) without changing UI call sites.

enum TruMatchPurpose {
  dating,
  serious,
  exploring,
  companionship;

  String get label {
    switch (this) {
      case TruMatchPurpose.dating:
        return 'Dating';
      case TruMatchPurpose.serious:
        return 'Serious';
      case TruMatchPurpose.exploring:
        return 'Exploring';
      case TruMatchPurpose.companionship:
        return 'Companionship';
    }
  }
}

extension TruMatchPurposeX on TruMatchPurpose {
  static TruMatchPurpose tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final p in TruMatchPurpose.values) {
      if (p.name.toLowerCase() == v) return p;
    }
    // Back-compat for older “Dating/Friendship/Networking” labels.
    if (v == 'friendship') return TruMatchPurpose.companionship;
    if (v == 'networking') return TruMatchPurpose.exploring;
    return TruMatchPurpose.dating;
  }
}

@immutable
class TruSyncBoundaries {
  final bool showRomanticContent;
  final bool allowNsfw;
  final bool allowAlcohol;

  const TruSyncBoundaries({required this.showRomanticContent, required this.allowNsfw, required this.allowAlcohol});

  factory TruSyncBoundaries.defaults() => const TruSyncBoundaries(showRomanticContent: true, allowNsfw: false, allowAlcohol: true);

  TruSyncBoundaries copyWith({bool? showRomanticContent, bool? allowNsfw, bool? allowAlcohol}) =>
      TruSyncBoundaries(showRomanticContent: showRomanticContent ?? this.showRomanticContent, allowNsfw: allowNsfw ?? this.allowNsfw, allowAlcohol: allowAlcohol ?? this.allowAlcohol);

  Map<String, dynamic> toJson() => {'showRomanticContent': showRomanticContent, 'allowNsfw': allowNsfw, 'allowAlcohol': allowAlcohol};

  factory TruSyncBoundaries.fromJson(Map<String, dynamic> json) => TruSyncBoundaries(
        showRomanticContent: json['showRomanticContent'] as bool? ?? true,
        allowNsfw: json['allowNsfw'] as bool? ?? false,
        allowAlcohol: json['allowAlcohol'] as bool? ?? true,
      );
}

@immutable
class TruSyncPreferences {
  final TruMatchPurpose purpose;
  final int minAge;
  final int maxAge;
  final double maxDistanceMiles;
  final bool verifiedOnly;
  final TruSyncBoundaries boundaries;

  /// Emotional bandwidth protection.
  final int activeMatchLimit;
  final bool lowEnergyMode;
  final bool paused;

  /// Optional trust knobs.
  final bool backgroundVisibilityEnabled;

  const TruSyncPreferences({
    required this.purpose,
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceMiles,
    required this.verifiedOnly,
    required this.boundaries,
    required this.activeMatchLimit,
    required this.lowEnergyMode,
    required this.paused,
    required this.backgroundVisibilityEnabled,
  });

  factory TruSyncPreferences.defaults() => TruSyncPreferences(
        purpose: TruMatchPurpose.dating,
        minAge: 21,
        maxAge: 34,
        maxDistanceMiles: 15,
        verifiedOnly: false,
        boundaries: TruSyncBoundaries.defaults(),
        activeMatchLimit: 3,
        lowEnergyMode: false,
        paused: false,
        backgroundVisibilityEnabled: false,
      );

  TruSyncPreferences copyWith({
    TruMatchPurpose? purpose,
    int? minAge,
    int? maxAge,
    double? maxDistanceMiles,
    bool? verifiedOnly,
    TruSyncBoundaries? boundaries,
    int? activeMatchLimit,
    bool? lowEnergyMode,
    bool? paused,
    bool? backgroundVisibilityEnabled,
  }) {
    return TruSyncPreferences(
      purpose: purpose ?? this.purpose,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceMiles: maxDistanceMiles ?? this.maxDistanceMiles,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      boundaries: boundaries ?? this.boundaries,
      activeMatchLimit: activeMatchLimit ?? this.activeMatchLimit,
      lowEnergyMode: lowEnergyMode ?? this.lowEnergyMode,
      paused: paused ?? this.paused,
      backgroundVisibilityEnabled: backgroundVisibilityEnabled ?? this.backgroundVisibilityEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'purpose': purpose.name,
        'minAge': minAge,
        'maxAge': maxAge,
        'maxDistanceMiles': maxDistanceMiles,
        'verifiedOnly': verifiedOnly,
        'boundaries': boundaries.toJson(),
        'activeMatchLimit': activeMatchLimit,
        'lowEnergyMode': lowEnergyMode,
        'paused': paused,
        'backgroundVisibilityEnabled': backgroundVisibilityEnabled,
      };

  factory TruSyncPreferences.fromJson(Map<String, dynamic> json) => TruSyncPreferences(
        purpose: TruMatchPurposeX.tryParse(json['purpose'] as String?),
        minAge: (json['minAge'] as num?)?.round() ?? 21,
        maxAge: (json['maxAge'] as num?)?.round() ?? 34,
        maxDistanceMiles: (json['maxDistanceMiles'] as num?)?.toDouble() ?? 15,
        verifiedOnly: json['verifiedOnly'] as bool? ?? false,
        boundaries: TruSyncBoundaries.fromJson((json['boundaries'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{}),
        activeMatchLimit: (json['activeMatchLimit'] as num?)?.round() ?? 3,
        lowEnergyMode: json['lowEnergyMode'] as bool? ?? false,
        paused: json['paused'] as bool? ?? false,
        backgroundVisibilityEnabled: json['backgroundVisibilityEnabled'] as bool? ?? false,
      );
}

@immutable
class TruSyncState {
  final String userId;
  final bool enabled;
  final TruSyncPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruSyncState({required this.userId, required this.enabled, required this.preferences, required this.createdAt, required this.updatedAt});

  factory TruSyncState.defaults(String userId) {
    final now = DateTime.now();
    return TruSyncState(userId: userId, enabled: false, preferences: TruSyncPreferences.defaults(), createdAt: now, updatedAt: now);
  }

  TruSyncState copyWith({bool? enabled, TruSyncPreferences? preferences, DateTime? updatedAt}) {
    return TruSyncState(userId: userId, enabled: enabled ?? this.enabled, preferences: preferences ?? this.preferences, createdAt: createdAt, updatedAt: updatedAt ?? this.updatedAt);
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'enabled': enabled,
        'preferences': preferences.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruSyncState.fromJson(Map<String, dynamic> json) => TruSyncState(
        userId: (json['userId'] as String?) ?? '',
        enabled: json['enabled'] as bool? ?? false,
        preferences: TruSyncPreferences.fromJson((json['preferences'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{}),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

@immutable
class TruCompatibilityLayer {
  final String key;
  final String title;
  final int score;
  final String note;

  const TruCompatibilityLayer({required this.key, required this.title, required this.score, required this.note});

  Map<String, dynamic> toJson() => {'key': key, 'title': title, 'score': score, 'note': note};

  factory TruCompatibilityLayer.fromJson(Map<String, dynamic> json) => TruCompatibilityLayer(
        key: (json['key'] as String?) ?? 'unknown',
        title: (json['title'] as String?) ?? 'Unknown',
        score: (json['score'] as num?)?.round() ?? 70,
        note: (json['note'] as String?) ?? '',
      );
}

@immutable
class TruPairCompatibilityReport {
  final String viewerUserId;
  final String targetUserId;
  final TruMatchPurpose purpose;
  final int overall;
  final List<TruCompatibilityLayer> layers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruPairCompatibilityReport({
    required this.viewerUserId,
    required this.targetUserId,
    required this.purpose,
    required this.overall,
    required this.layers,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'viewerUserId': viewerUserId,
        'targetUserId': targetUserId,
        'purpose': purpose.name,
        'overall': overall,
        'layers': layers.map((e) => e.toJson()).toList(growable: false),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruPairCompatibilityReport.fromJson(Map<String, dynamic> json) => TruPairCompatibilityReport(
        viewerUserId: (json['viewerUserId'] as String?) ?? '',
        targetUserId: (json['targetUserId'] as String?) ?? '',
        purpose: TruMatchPurposeX.tryParse(json['purpose'] as String?),
        overall: (json['overall'] as num?)?.round() ?? 72,
        layers: ((json['layers'] as List?) ?? const <Object>[])
            .whereType<Map>()
            .map((e) => TruCompatibilityLayer.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

@immutable
class TruSyncSuggestion {
  final String id;
  final String viewerUserId;
  final String targetUserId;
  final TruPairCompatibilityReport report;
  final List<String> reasons;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruSyncSuggestion({
    required this.id,
    required this.viewerUserId,
    required this.targetUserId,
    required this.report,
    required this.reasons,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'viewerUserId': viewerUserId,
        'targetUserId': targetUserId,
        'report': report.toJson(),
        'reasons': reasons,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruSyncSuggestion.fromJson(Map<String, dynamic> json) => TruSyncSuggestion(
        id: (json['id'] as String?) ?? '',
        viewerUserId: (json['viewerUserId'] as String?) ?? '',
        targetUserId: (json['targetUserId'] as String?) ?? '',
        report: TruPairCompatibilityReport.fromJson((json['report'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{}),
        reasons: ((json['reasons'] as List?) ?? const <Object>[]).whereType<String>().toList(growable: false),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

enum TruActiveMatchStatus { active, paused, closed }

/// Primary interaction signals for match flow.
///
/// - Spark: romantic / connection intent
/// - Glow: friendly / safe engagement
/// - Aura: identity signal (non-matching, context shaping)
enum TruInteractionSignal { spark, glow, aura }

extension TruInteractionSignalX on TruInteractionSignal {
  static TruInteractionSignal tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final s in TruInteractionSignal.values) {
      if (s.name.toLowerCase() == v) return s;
    }
    return TruInteractionSignal.glow;
  }

  String get label {
    switch (this) {
      case TruInteractionSignal.spark:
        return 'Spark';
      case TruInteractionSignal.glow:
        return 'Glow';
      case TruInteractionSignal.aura:
        return 'Aura';
    }
  }
}

/// Connection journey stage after a match forms.
enum TruConnectionStage { matched, chatting, guided, matchroom, planning, closed }

extension TruConnectionStageX on TruConnectionStage {
  static TruConnectionStage tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final s in TruConnectionStage.values) {
      if (s.name.toLowerCase() == v) return s;
    }
    return TruConnectionStage.matched;
  }
}

@immutable
class TruInteractionSignalEvent {
  final String id;
  final String fromUserId;
  final String toUserId;
  final TruInteractionSignal signal;
  final bool mutual;
  final bool createdMatch;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruInteractionSignalEvent({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.signal,
    required this.mutual,
    required this.createdMatch,
    required this.createdAt,
    required this.updatedAt,
  });

  TruInteractionSignalEvent copyWith({bool? mutual, bool? createdMatch, DateTime? updatedAt}) => TruInteractionSignalEvent(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        signal: signal,
        mutual: mutual ?? this.mutual,
        createdMatch: createdMatch ?? this.createdMatch,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'signal': signal.name,
        'mutual': mutual,
        'createdMatch': createdMatch,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruInteractionSignalEvent.fromJson(Map<String, dynamic> json) => TruInteractionSignalEvent(
        id: (json['id'] as String?) ?? '',
        fromUserId: (json['fromUserId'] as String?) ?? '',
        toUserId: (json['toUserId'] as String?) ?? '',
        signal: TruInteractionSignalX.tryParse(json['signal'] as String?),
        mutual: json['mutual'] as bool? ?? false,
        createdMatch: json['createdMatch'] as bool? ?? false,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

@immutable
class TruMatchroom {
  final String id;
  final String matchId;
  final int level;
  final List<String> prompts;
  final bool voiceUnlocked;
  final bool videoUnlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruMatchroom({
    required this.id,
    required this.matchId,
    required this.level,
    required this.prompts,
    required this.voiceUnlocked,
    required this.videoUnlocked,
    required this.createdAt,
    required this.updatedAt,
  });

  TruMatchroom copyWith({int? level, List<String>? prompts, bool? voiceUnlocked, bool? videoUnlocked, DateTime? updatedAt}) => TruMatchroom(
        id: id,
        matchId: matchId,
        level: level ?? this.level,
        prompts: prompts ?? this.prompts,
        voiceUnlocked: voiceUnlocked ?? this.voiceUnlocked,
        videoUnlocked: videoUnlocked ?? this.videoUnlocked,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'matchId': matchId,
        'level': level,
        'prompts': prompts,
        'voiceUnlocked': voiceUnlocked,
        'videoUnlocked': videoUnlocked,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruMatchroom.fromJson(Map<String, dynamic> json) => TruMatchroom(
        id: (json['id'] as String?) ?? '',
        matchId: (json['matchId'] as String?) ?? '',
        level: (json['level'] as num?)?.round() ?? 1,
        prompts: ((json['prompts'] as List?) ?? const <Object>[]).whereType<String>().toList(growable: false),
        voiceUnlocked: json['voiceUnlocked'] as bool? ?? false,
        videoUnlocked: json['videoUnlocked'] as bool? ?? false,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

extension TruActiveMatchStatusX on TruActiveMatchStatus {
  static TruActiveMatchStatus tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final s in TruActiveMatchStatus.values) {
      if (s.name.toLowerCase() == v) return s;
    }
    return TruActiveMatchStatus.active;
  }
}

@immutable
class TruActiveMatch {
  final String id;
  final String viewerUserId;
  final String targetUserId;
  final String chatId;
  final TruActiveMatchStatus status;
  final TruInteractionSignal signal;
  final TruConnectionStage stage;
  final String? matchroomId;
  final String? pauseNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruActiveMatch({
    required this.id,
    required this.viewerUserId,
    required this.targetUserId,
    required this.chatId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.signal = TruInteractionSignal.glow,
    this.stage = TruConnectionStage.matched,
    this.matchroomId,
    this.pauseNote,
  });

  TruActiveMatch copyWith({TruActiveMatchStatus? status, TruInteractionSignal? signal, TruConnectionStage? stage, String? matchroomId, String? pauseNote, DateTime? updatedAt}) => TruActiveMatch(
        id: id,
        viewerUserId: viewerUserId,
        targetUserId: targetUserId,
        chatId: chatId,
        status: status ?? this.status,
        signal: signal ?? this.signal,
        stage: stage ?? this.stage,
        matchroomId: matchroomId ?? this.matchroomId,
        pauseNote: pauseNote ?? this.pauseNote,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'viewerUserId': viewerUserId,
        'targetUserId': targetUserId,
        'chatId': chatId,
        'status': status.name,
        'signal': signal.name,
        'stage': stage.name,
        'matchroomId': matchroomId,
        'pauseNote': pauseNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruActiveMatch.fromJson(Map<String, dynamic> json) => TruActiveMatch(
        id: (json['id'] as String?) ?? '',
        viewerUserId: (json['viewerUserId'] as String?) ?? '',
        targetUserId: (json['targetUserId'] as String?) ?? '',
        chatId: (json['chatId'] as String?) ?? '',
        status: TruActiveMatchStatusX.tryParse(json['status'] as String?),
        signal: TruInteractionSignalX.tryParse(json['signal'] as String?),
        stage: TruConnectionStageX.tryParse(json['stage'] as String?),
        matchroomId: json['matchroomId'] as String?,
        pauseNote: json['pauseNote'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}
