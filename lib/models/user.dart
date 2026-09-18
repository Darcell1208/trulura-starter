import 'dart:convert';

class User {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? bio;
  final String? profileImage;
  final int age;
  final String? location;
  final String? pronouns;
  final List<String> languages;
  final List<String> intents;
  final List<String> moodTags;
  final List<String> interests;
  final String? socialPreference;
  final String? expressionPromptAnswer;
  final String? expressionVibeTag;
  final String? expressionShortPost;

  /// Identity / trust system (v1)
  ///
  /// These fields are designed to work in an **auth-only** setup (local cache +
  /// optional auth.user_metadata), while still being compatible with a future
  /// `public.profiles` / `identity_modes` schema.
  final TruIdentityMode activeIdentityMode;
  final bool anonymousOverlayEnabled;
  final TruTemperament temperament;

  /// Verification / trust indicators (user-controlled visibility).
  final TruVerificationLevel verificationLevel;
  /// Internal-only trust score (0-100). Never show exact number publicly.
  final int trustScore;
  final TruRiskLevel riskLevel;
  final DateTime? trustLastUpdated;
  final bool showVerificationBadge;
  final bool showTrustIndicator;

  /// Privacy settings.
  final bool allowScreenshots;
  final bool messageAutoDelete;
  final TruProfileVisibility profileVisibility;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// The field values as read from a profiles row, or null if this User was
  /// never hydrated from one. User() seeds non-null defaults, so without this
  /// "not answered" and "answered with the default" are the same object.
  /// Not serialised: a User restored from the local cache is not hydrated.
  final Map<String, dynamic>? hydratedSnapshot;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio,
    this.profileImage,
    required this.age,
    this.location,
    this.pronouns,
    this.languages = const [],
    this.intents = const [],
    this.moodTags = const [],
    this.interests = const [],
    this.socialPreference,
    this.expressionPromptAnswer,
    this.expressionVibeTag,
    this.expressionShortPost,

    this.activeIdentityMode = TruIdentityMode.social,
    this.anonymousOverlayEnabled = false,
    this.temperament = TruTemperament.oldSoul,
    this.verificationLevel = TruVerificationLevel.level0,
    this.trustScore = 70,
    this.riskLevel = TruRiskLevel.low,
    this.trustLastUpdated,
    this.showVerificationBadge = true,
    this.showTrustIndicator = true,
    this.allowScreenshots = true,
    this.messageAutoDelete = false,
    this.profileVisibility = TruProfileVisibility.public,

    required this.createdAt,
    required this.updatedAt,
    this.hydratedSnapshot,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'bio': bio,
    'profileImage': profileImage,
    'age': age,
    'location': location,
    'pronouns': pronouns,
    'languages': languages,
    'intents': intents,
    'moodTags': moodTags,
    'interests': interests,
    'socialPreference': socialPreference,
    'expressionPromptAnswer': expressionPromptAnswer,
    'expressionVibeTag': expressionVibeTag,
    'expressionShortPost': expressionShortPost,

    'activeIdentityMode': activeIdentityMode.name,
    'anonymousOverlayEnabled': anonymousOverlayEnabled,
    'temperament': temperament.name,
    'verificationLevel': verificationLevel.name,
    'trustScore': trustScore,
    'riskLevel': riskLevel.name,
    'trustLastUpdated': trustLastUpdated?.toIso8601String(),
    'showVerificationBadge': showVerificationBadge,
    'showTrustIndicator': showTrustIndicator,
    'allowScreenshots': allowScreenshots,
    'messageAutoDelete': messageAutoDelete,
    'profileVisibility': profileVisibility.name,

    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static List<String> _stringListFromJson(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Object>()
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  /// Vibe only: the profile column is authoritative, including when empty.
  /// Older cache names describe the same concept; Mood and temperament do not.
  static List<String> vibeFromJson(Map<String, dynamic> json) {
    if (json.containsKey('vibe')) {
      final vibe = (json['vibe'] as String?)?.trim() ?? '';
      return vibe.isEmpty ? const <String>[] : <String>[vibe];
    }
    return _stringListFromJson(json['moodTags'] ?? json['mood_tags']);
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? (json['display_name'] as String?) ?? '',
    username: (json['username'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    bio: (json['bio'] as String?) ?? '',
    profileImage: (json['profileImage'] as String?) ??
        (json['profile_photo_url'] as String?) ??
        (json['avatar_url'] as String?) ??
        '',
    age: (json['age'] as int?) ?? 18,
    location: json['location'] as String?,
    pronouns: json['pronouns'] as String?,
    languages: _stringListFromJson(json['languages']),
    intents: _stringListFromJson(json['intents']),
    moodTags: vibeFromJson(json),
    interests: _stringListFromJson(json['interests']),
    socialPreference: ((json['socialPreference'] as String?) ??
                (json['social_preference'] as String?))
            ?.trim()
            .isEmpty ??
        true
        ? null
        : (((json['socialPreference'] as String?) ??
                (json['social_preference'] as String?))
            ?.trim()),
    expressionPromptAnswer:
        (((json['expressionPromptAnswer'] as String?) ??
                    (json['expression_prompt_answer'] as String?))
                ?.trim()
                .isEmpty ??
            true)
            ? null
            : (((json['expressionPromptAnswer'] as String?) ??
                    (json['expression_prompt_answer'] as String?))
                ?.trim()),
    expressionVibeTag:
        (((json['expressionVibeTag'] as String?) ??
                    (json['expression_vibe_tag'] as String?))
                ?.trim()
                .isEmpty ??
            true)
            ? null
            : (((json['expressionVibeTag'] as String?) ??
                    (json['expression_vibe_tag'] as String?))
                ?.trim()),
    expressionShortPost:
        (((json['expressionShortPost'] as String?) ??
                    (json['expression_short_post'] as String?))
                ?.trim()
                .isEmpty ??
            true)
            ? null
            : (((json['expressionShortPost'] as String?) ??
                    (json['expression_short_post'] as String?))
                ?.trim()),

    activeIdentityMode: TruIdentityModeX.tryParse(
            (json['activeIdentityMode'] ?? json['active_identity_mode'])
                as String?) ??
        TruIdentityMode.social,
    anonymousOverlayEnabled:
        (json['anonymousOverlayEnabled'] as bool?) ??
        (json['anonymous_overlay_enabled'] as bool?) ??
        false,
    // Three keys, newest first. 'temperament' is what this writes now;
    // 'vibeLabel' is the old local-cache key and 'vibe_status' the old column,
    // both read so an existing cache or an un-migrated database still hydrates.
    // Reading an older NAME for the same concept is fine -- what the decision
    // record forbids is reading a DIFFERENT concept's storage as a fallback.
    temperament: TruTemperamentX.tryParse(
            (json['temperament'] ?? json['vibeLabel'] ?? json['vibe_status'])
                as String?) ??
        TruTemperament.oldSoul,
    verificationLevel: TruVerificationLevelX.tryParse(
            (json['verificationLevel'] ?? json['verification_level'])
                as String?) ??
        TruVerificationLevel.level0,
    trustScore: (json['trustScore'] as int?) ?? 70,
    riskLevel: TruRiskLevelX.tryParse(json['riskLevel'] as String?) ?? TruRiskLevel.low,
    trustLastUpdated: (json['trustLastUpdated'] as String?) == null ? null : DateTime.tryParse(json['trustLastUpdated'] as String),
    showVerificationBadge:
        (json['showVerificationBadge'] as bool?) ??
        (json['show_verification_badge'] as bool?) ??
        true,
    showTrustIndicator:
        (json['showTrustIndicator'] as bool?) ??
        (json['show_trust_indicator'] as bool?) ??
        true,
    allowScreenshots:
        (json['allowScreenshots'] as bool?) ??
        (json['allow_screenshots'] as bool?) ??
        true,
    messageAutoDelete:
        (json['messageAutoDelete'] as bool?) ??
        (json['message_auto_delete'] as bool?) ??
        false,
    profileVisibility: TruProfileVisibilityX.tryParse(
            (json['profileVisibility'] ?? json['profile_visibility'])
                as String?) ??
        TruProfileVisibility.public,

    createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '').toString()) ?? DateTime.now(),
    updatedAt: DateTime.tryParse((json['updatedAt'] ?? json['updated_at'] ?? '').toString()) ?? DateTime.now(),
  );

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? bio,
    String? profileImage,
    int? age,
    String? location,
    String? pronouns,
    List<String>? languages,
    List<String>? intents,
    List<String>? moodTags,
    List<String>? interests,
    String? socialPreference,
    String? expressionPromptAnswer,
    String? expressionVibeTag,
    String? expressionShortPost,

    TruIdentityMode? activeIdentityMode,
    bool? anonymousOverlayEnabled,
    TruTemperament? temperament,
    TruVerificationLevel? verificationLevel,
    int? trustScore,
    TruRiskLevel? riskLevel,
    DateTime? trustLastUpdated,
    bool? showVerificationBadge,
    bool? showTrustIndicator,
    bool? allowScreenshots,
    bool? messageAutoDelete,
    TruProfileVisibility? profileVisibility,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    bio: bio ?? this.bio,
    profileImage: profileImage ?? this.profileImage,
    age: age ?? this.age,
    location: location ?? this.location,
    pronouns: pronouns ?? this.pronouns,
    languages: languages ?? this.languages,
    intents: intents ?? this.intents,
    moodTags: moodTags ?? this.moodTags,
    interests: interests ?? this.interests,
    socialPreference: socialPreference ?? this.socialPreference,
    expressionPromptAnswer:
        expressionPromptAnswer ?? this.expressionPromptAnswer,
    expressionVibeTag: expressionVibeTag ?? this.expressionVibeTag,
    expressionShortPost: expressionShortPost ?? this.expressionShortPost,

    activeIdentityMode: activeIdentityMode ?? this.activeIdentityMode,
    anonymousOverlayEnabled: anonymousOverlayEnabled ?? this.anonymousOverlayEnabled,
    temperament: temperament ?? this.temperament,
    verificationLevel: verificationLevel ?? this.verificationLevel,
    trustScore: trustScore ?? this.trustScore,
    riskLevel: riskLevel ?? this.riskLevel,
    trustLastUpdated: trustLastUpdated ?? this.trustLastUpdated,
    showVerificationBadge: showVerificationBadge ?? this.showVerificationBadge,
    showTrustIndicator: showTrustIndicator ?? this.showTrustIndicator,
    allowScreenshots: allowScreenshots ?? this.allowScreenshots,
    messageAutoDelete: messageAutoDelete ?? this.messageAutoDelete,
    profileVisibility: profileVisibility ?? this.profileVisibility,

    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    hydratedSnapshot: hydratedSnapshot,
  );

  /// True only for a User read back from a profiles row (or a copy of one).
  bool get isHydrated => hydratedSnapshot != null;

  /// A copy that records the current values as what was read. Call only where
  /// a profiles row was actually fetched.
  ///
  /// Copies fields verbatim. Not via fromJson: that turns a null bio or photo
  /// into '', so the copy would differ from its own snapshot and every save
  /// would blank those two fields.
  User markHydrated() => copyWithSnapshot(toJson());

  /// [copyWith] cannot set the snapshot, on purpose: a caller editing fields
  /// must not be able to move the baseline they are diffed against.
  User copyWithSnapshot(Map<String, dynamic> snapshot) => User(
        id: id,
        name: name,
        username: username,
        email: email,
        bio: bio,
        profileImage: profileImage,
        age: age,
        location: location,
        pronouns: pronouns,
        languages: languages,
        intents: intents,
        moodTags: moodTags,
        interests: interests,
        socialPreference: socialPreference,
        expressionPromptAnswer: expressionPromptAnswer,
        expressionVibeTag: expressionVibeTag,
        expressionShortPost: expressionShortPost,
        activeIdentityMode: activeIdentityMode,
        anonymousOverlayEnabled: anonymousOverlayEnabled,
        temperament: temperament,
        verificationLevel: verificationLevel,
        trustScore: trustScore,
        riskLevel: riskLevel,
        trustLastUpdated: trustLastUpdated,
        showVerificationBadge: showVerificationBadge,
        showTrustIndicator: showTrustIndicator,
        allowScreenshots: allowScreenshots,
        messageAutoDelete: messageAutoDelete,
        profileVisibility: profileVisibility,
        createdAt: createdAt,
        updatedAt: updatedAt,
        hydratedSnapshot: Map<String, dynamic>.unmodifiable(snapshot),
      );

  /// toJson keys whose values differ from [hydratedSnapshot]. Timestamps are
  /// bookkeeping, not answers, and are never dirty. Empty when unhydrated --
  /// callers must check [isHydrated] first rather than read that as "clean".
  Set<String> dirtyFields() {
    final snapshot = hydratedSnapshot;
    if (snapshot == null) return const <String>{};
    final current = toJson();
    return {
      for (final key in current.keys)
        if (key != 'createdAt' &&
            key != 'updatedAt' &&
            jsonEncode(current[key]) != jsonEncode(snapshot[key]))
          key,
    };
  }

  static bool _looksLikeEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    return trimmed.contains('@');
  }

  static String? _emailLocalPart(String? email) {
    final trimmed = email?.trim() ?? '';
    if (!trimmed.contains('@')) return null;
    final local = trimmed.split('@').first.trim();
    return local.isEmpty ? null : local;
  }

  /// The display name, or null when there is nothing safe to show.
  ///
  /// Null is a real answer here, not an error: an empty name, an email-shaped
  /// name, and a name equal to the email's local part are all cases where
  /// showing the raw value would leak or mislead. Callers that must render
  /// something pass their own fallback through [publicDisplayNameFrom];
  /// callers that would rather render nothing use this and omit the widget.
  /// FeedCard uses this one — a placeholder name there was indistinguishable
  /// from a real one (Build Status known issue 31).
  static String? publicDisplayNameOrNull(String? raw, {String? email}) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (_looksLikeEmail(trimmed)) return null;
    final local = _emailLocalPart(email);
    if (local != null && trimmed.toLowerCase() == local.toLowerCase()) {
      return null;
    }
    return trimmed;
  }

  static String publicDisplayNameFrom(
    String? raw, {
    String? email,
    String fallback = 'New member',
  }) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    if (_looksLikeEmail(trimmed)) return fallback;
    final local = _emailLocalPart(email);
    if (local != null && trimmed.toLowerCase() == local.toLowerCase()) {
      return fallback;
    }
    return trimmed;
  }

  static String? publicUsernameFrom(String? raw, {String? email}) {
    final trimmed = raw?.trim().replaceFirst(RegExp(r'^@+'), '') ?? '';
    if (trimmed.isEmpty) return null;
    if (_looksLikeEmail(trimmed)) return null;
    final local = _emailLocalPart(email);
    if (local != null && trimmed.toLowerCase() == local.toLowerCase()) {
      return null;
    }
    return trimmed;
  }

  String get publicDisplayName =>
      publicDisplayNameFrom(name, email: email, fallback: 'New member');

  String? get publicUsername => publicUsernameFrom(username, email: email);
}

/// Identity mode is a *persona layer* selection. It is separate from
/// [TruExperienceMode] (feed participation).
///
/// Anonymous is intentionally modeled as an overlay toggle (not a mode) so it
/// can apply across modes.
enum TruIdentityMode { social, friendship, dating, creator, luxe, vent }

extension TruIdentityModeX on TruIdentityMode {
  static TruIdentityMode? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruIdentityMode.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruIdentityMode.social:
        return 'Social';
      case TruIdentityMode.friendship:
        return 'Friendship';
      case TruIdentityMode.dating:
        return 'Dating';
      case TruIdentityMode.creator:
        return 'Creator';
      case TruIdentityMode.luxe:
        return 'Luxe';
      case TruIdentityMode.vent:
        return 'Vent';
    }
  }
}

/// Dispositional temperament: stable, describes a person rather than a moment.
///
/// NOT the same object as the expressive Vibe in `profiles.vibe` (Reflective,
/// Dreamy, Calm, Flirty, Healing, Energetic, Creative), and not Mood. See
/// `docs/TruLura_PO_Decision_Vibe_And_Temperament.md`.
///
/// `contemplative` and `mending` were `reflective` and `healing`. They were
/// renamed because those two values also exist in the Vibe vocabulary, and
/// while they did, a value sitting in the wrong column could not be attributed
/// to a vocabulary by reading it -- not by a person and not by code. An
/// invariant that cannot be verified by inspection is not an invariant. The
/// sets are disjoint now, so `reflective` can only mean Vibe and
/// `contemplative` can only mean temperament.
enum TruTemperament {
  oldSoul,
  mending,
  contemplative,
  radiant,
  grounded,
  mysterious
}

extension TruTemperamentX on TruTemperament {
  static TruTemperament? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruTemperament.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruTemperament.oldSoul:
        return 'Old Soul';
      case TruTemperament.mending:
        return 'Mending';
      case TruTemperament.contemplative:
        return 'Contemplative';
      case TruTemperament.radiant:
        return 'Radiant';
      case TruTemperament.grounded:
        return 'Grounded';
      case TruTemperament.mysterious:
        return 'Mysterious';
    }
  }
}

enum TruVerificationLevel { level0, level1, level2, level3 }

extension TruVerificationLevelX on TruVerificationLevel {
  static TruVerificationLevel? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruVerificationLevel.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruVerificationLevel.level0:
        return 'Basic';
      case TruVerificationLevel.level1:
        return 'Standard';
      case TruVerificationLevel.level2:
        return 'Verified';
      case TruVerificationLevel.level3:
        return 'Trusted';
    }
  }
}

enum TruRiskLevel { low, medium, high }

extension TruRiskLevelX on TruRiskLevel {
  static TruRiskLevel? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruRiskLevel.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

enum TruProfileVisibility { public, friends, private }

extension TruProfileVisibilityX on TruProfileVisibility {
  static TruProfileVisibility? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruProfileVisibility.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruProfileVisibility.public:
        return 'Public';
      case TruProfileVisibility.friends:
        return 'Friends';
      case TruProfileVisibility.private:
        return 'Private';
    }
  }
}
