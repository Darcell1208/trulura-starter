import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/models/emotional_presence_state.dart';
import 'package:trulura/models/user.dart' as model;
import 'package:trulura/services/app_settings_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/supabase/supabase_config.dart';

class AppProvider with ChangeNotifier {
  String _appMode = 'Aura';
  model.User? _currentUser;
  bool _lowSocialBattery = false;
  bool _softModeEnabled = false;
  double _glowScaleUser = 1.0;
  bool _softModeGateCompleted = false;
  bool _creatorModeEnabled = false;
  bool _creatorApproved = false;
  bool _creatorOnboardingComplete = false;
  bool _hasAdvancedVerification = false;
  bool _hasBackgroundVerification = false;
  bool _hasLuxeInvite = false;
  bool _hasLuxeSubscription = false;
  bool _showLivesInFeed = true;
  String _livesInFeedFrequency = 'Normal';

  // Feed personalization (Section 4)
  double _feedContentIntensity = 0.65;
  double _feedCreatorWeight = 0.35;
  double _feedRomanticVisibility = 0.55;
  double _feedEmotionalSensitivity = 0.55;
  List<String> _feedTabOrder = const [
    'for_you',
    'aura',
    'spark',
    'vent',
    'trending',
  ];

  // Section 7: distribution controls
  double _feedDiscoveryBalance = 0.45;
  List<String> _feedMutedTopics = const <String>[];
  List<String> _feedMutedMoods = const <String>[];

  // Section 7 (expanded): switching + mood UI + transparency + low energy
  bool _smartFeedSwitchingEnabled = true;
  bool _moodAdaptiveUiEnabled = true;
  bool _transparencyExplainersEnabled = true;
  bool _lowEnergyFeedEnabled = false;

  /// Onboarding-selected usage mode.
  /// Allowed values: social | dating | both
  String _useMode = 'both';

  /// “Date Mode Only” — when enabled, TruLura behaves as a standalone TruDating app.
  bool _fullSyncModeEnabled = false;

  bool _initialized = false;
  bool _hasPersistedIntent = false;
  bool _hasPersistedMood = false;
  bool _askVibeAtStartup = false;
  bool _askIntentAtStartup = false;
  bool _rememberMoodIntent = true;
  String _appearanceMode = 'trulura';

  /// Locked primary navigation index for the MainShell bottom nav.
  ///
  /// 0 Home, 1 Messages, 2 Notifications, 3 Profile
  int _mainTabIndex = 0;

  StreamSubscription<AuthState>? _authSub;

  String get appMode => _appMode;
  model.User? get currentUser => _currentUser;
  bool get lowSocialBattery => _lowSocialBattery;
  bool get softModeEnabled => _softModeEnabled;
  bool get softModeGateCompleted => _softModeGateCompleted;
  bool get creatorModeEnabled => _creatorModeEnabled;
  bool get creatorApproved => _creatorApproved;
  bool get creatorOnboardingComplete => _creatorOnboardingComplete;
  bool get hasAdvancedVerification => _hasAdvancedVerification;
  bool get hasBackgroundVerification => _hasBackgroundVerification;
  bool get hasLuxeInvite => _hasLuxeInvite;
  bool get hasLuxeSubscription => _hasLuxeSubscription;
  bool get luxeEligible =>
      _hasLuxeInvite && _hasLuxeSubscription && _hasAdvancedVerification;
  bool get showLivesInFeed => _showLivesInFeed;
  String get livesInFeedFrequency => _livesInFeedFrequency;
  double get feedContentIntensity => _feedContentIntensity;
  double get feedCreatorWeight => _feedCreatorWeight;
  double get feedRomanticVisibility => _feedRomanticVisibility;
  double get feedEmotionalSensitivity => _feedEmotionalSensitivity;
  List<String> get feedTabOrder => _feedTabOrder;
  double get feedDiscoveryBalance => _feedDiscoveryBalance;
  List<String> get feedMutedTopics => _feedMutedTopics;
  List<String> get feedMutedMoods => _feedMutedMoods;
  bool get smartFeedSwitchingEnabled => _smartFeedSwitchingEnabled;
  bool get moodAdaptiveUiEnabled => _moodAdaptiveUiEnabled;
  bool get transparencyExplainersEnabled => _transparencyExplainersEnabled;
  bool get lowEnergyFeedEnabled => _lowEnergyFeedEnabled;
  String get useMode => _useMode;
  bool get fullSyncModeEnabled => _fullSyncModeEnabled;
  bool get initialized => _initialized;
  int get mainTabIndex => _mainTabIndex;
  bool get hasPersistedIntent => _hasPersistedIntent;
  bool get hasPersistedMood => _hasPersistedMood;
  bool get askVibeAtStartup => _askVibeAtStartup;
  bool get askIntentAtStartup => _askIntentAtStartup;
  bool get rememberMoodIntent => _rememberMoodIntent;
  String get appearanceMode => _appearanceMode;
  TruEmotionalPresenceState get emotionalPresenceState =>
      TruEmotionalPresenceState.derive(
        softMode: _softModeEnabled,
        lowEnergy: isLowEnergyContext,
        anonymous: _currentUser?.anonymousOverlayEnabled ?? false,
        vibe: _currentUser?.vibeLabel.label ?? 'Old Soul',
        moods: _currentUser?.moodTags ?? const <String>[],
      );

  /// Whether the authed user still needs to complete the Phase-1 onboarding flow.
  ///
  /// Entry onboarding is complete once the user has chosen an intent
  /// and at least one mood/vibe tag. Profile setup stays optional.
  bool get needsOnboarding {
    final hasIntent = _hasPersistedIntent ||
        _stringListOrEmpty(_currentUser?.intents).isNotEmpty;
    final hasMood = _hasPersistedMood ||
        _stringListOrEmpty(_currentUser?.moodTags).isNotEmpty;
    return !(hasIntent && hasMood);
  }

  /// 0.3–0.4 is roughly a 60–70% reduction (Soft Mode requirement).
  double get glowScale =>
      (_softModeEnabled ? 0.35 : 1.0) *
      _glowScaleUser *
      emotionalPresenceState.glowScale;

  double get glowScaleUser => _glowScaleUser;

  Duration get motionDuration => Duration(
        milliseconds: ((_softModeEnabled ? 360 : 180) /
                emotionalPresenceState.motionScale.clamp(0.35, 1.2))
            .round(),
      );

  /// When enabled, the app reduces stimulation: fewer boosted slots, calmer motion,
  /// softer visuals. This is separate from Soft Mode (which is primarily an
  /// accessibility + motion toggle).
  bool get isLowEnergyContext => _lowEnergyFeedEnabled || _lowSocialBattery;

  /// Compatibility alias for older call sites / snippets.
  void setSoftMode(bool value) => unawaited(setSoftModeEnabled(value));

  /// Global scaling factor for glow intensity (0.0–1.5 typical).
  void setGlowScale(double value) => unawaited(setGlowScaleUser(value));

  void setAppMode(String mode) {
    _appMode = mode;
    notifyListeners();
  }

  void setMainTabIndex(int index) {
    if (index == _mainTabIndex) return;
    _mainTabIndex = index.clamp(0, 3);
    notifyListeners();
  }

  void setCurrentUser(model.User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void toggleLowSocialBattery() {
    _lowSocialBattery = !_lowSocialBattery;
    notifyListeners();
  }

  List<String> _stringListOrEmpty(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Object>()
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  Future<void> _syncCurrentUserFromSupabase() async {
    final supabaseUser = SupabaseConfig.auth.currentUser;

    if (supabaseUser == null) {
      _currentUser = null;
      _hasPersistedIntent = false;
      _hasPersistedMood = false;
      notifyListeners();
      return;
    }

    model.User? cachedUser;
    try {
      cachedUser = await UserService().getCurrentUser();
      final rawMetadata = supabaseUser.userMetadata;
      final metadata = rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : <String, dynamic>{};
      final results = await Future.wait([
        SupabaseConfig.client
            .from('profiles')
            .select()
            .eq('id', supabaseUser.id)
            .maybeSingle(),
        SupabaseConfig.client
            .from('matchmaking_profiles')
            .select('intent, preferences')
            .eq('user_id', supabaseUser.id)
            .eq('active', true)
            .maybeSingle(),
        SupabaseConfig.client
            .from('user_states')
            .select('mood_tag')
            .eq('user_id', supabaseUser.id)
            .maybeSingle(),
      ]);
      final profile = results[0];
      final matchmakingProfile = results[1];
      final userState = results[2];
      final schemaIntent =
          matchmakingProfile?['intent']?.toString().trim() ?? '';
      final schemaMood = userState?['mood_tag']?.toString().trim() ?? '';
      _hasPersistedIntent = schemaIntent.isNotEmpty;
      _hasPersistedMood = schemaMood.isNotEmpty;

      final normalizedProfile =
          Map<String, dynamic>.from(profile ?? <String, dynamic>{});
      normalizedProfile['id'] =
          (normalizedProfile['id'] as String?) ?? supabaseUser.id;
      normalizedProfile['name'] = (normalizedProfile['name'] as String?) ??
          (normalizedProfile['display_name'] as String?) ??
          metadata['name']?.toString() ??
          '';
      normalizedProfile['username'] =
          (normalizedProfile['username'] as String?) ??
              metadata['username']?.toString() ??
              '';
      normalizedProfile['email'] =
          (normalizedProfile['email'] as String?) ?? supabaseUser.email ?? '';
      normalizedProfile['display_name'] =
          (normalizedProfile['display_name'] as String?) ??
              (normalizedProfile['name'] as String?) ??
              (metadata['name'] as String?) ??
              '';
      normalizedProfile['bio'] = (normalizedProfile['bio'] as String?) ??
          (normalizedProfile['about_me'] as String?) ??
          '';
      normalizedProfile['profileImage'] =
          (normalizedProfile['profileImage'] as String?) ??
              (normalizedProfile['profile_photo_url'] as String?) ??
              (normalizedProfile['avatar_url'] as String?) ??
              '';
      final matchmakingPreferences = matchmakingProfile?['preferences'];
      final profileInterests = matchmakingPreferences is Map
          ? _stringListOrEmpty(matchmakingPreferences['interests'])
          : const <String>[];
      normalizedProfile['avatar_url'] =
          (normalizedProfile['avatar_url'] as String?) ??
              (normalizedProfile['profileImage'] as String?) ??
              '';
      normalizedProfile['age'] = (normalizedProfile['age'] as int?) ?? 18;
      final profileIntents = _stringListOrEmpty(normalizedProfile['intents']);
      final intents = profileIntents.isNotEmpty
          ? profileIntents
          : (schemaIntent.isNotEmpty
              ? <String>[schemaIntent]
              : const <String>[]);
      final profileMoodTags = _stringListOrEmpty(
        normalizedProfile['moodTags'] ?? normalizedProfile['mood_tags'],
      );
      final moodTags = profileMoodTags.isNotEmpty
          ? profileMoodTags
          : (schemaMood.isNotEmpty ? <String>[schemaMood] : const <String>[]);
      normalizedProfile['intents'] = intents.isNotEmpty
          ? intents
          : (cachedUser?.intents ?? const <String>[]);
      normalizedProfile['moodTags'] = moodTags.isNotEmpty
          ? moodTags
          : (cachedUser?.moodTags ?? const <String>[]);
      normalizedProfile['interests'] = profileInterests.isNotEmpty
          ? profileInterests
          : (cachedUser?.interests ?? const <String>[]);
      normalizedProfile['location'] =
          (normalizedProfile['location'] as String?)?.trim().isNotEmpty == true
              ? (normalizedProfile['location'] as String?)?.trim()
              : cachedUser?.location;
      normalizedProfile['pronouns'] =
          (normalizedProfile['pronouns'] as String?)?.trim().isNotEmpty == true
              ? (normalizedProfile['pronouns'] as String?)?.trim()
              : cachedUser?.pronouns;
      normalizedProfile['languages'] = _stringListOrEmpty(
        normalizedProfile['languages'],
      ).isNotEmpty
          ? _stringListOrEmpty(normalizedProfile['languages'])
          : (cachedUser?.languages ?? const <String>[]);
      normalizedProfile['socialPreference'] =
          (normalizedProfile['social_preference'] as String?)
                      ?.trim()
                      .isNotEmpty ==
                  true
              ? (normalizedProfile['social_preference'] as String?)?.trim()
              : cachedUser?.socialPreference;
      normalizedProfile['expressionPromptAnswer'] =
          (normalizedProfile['expression_prompt_answer'] as String?)
                      ?.trim()
                      .isNotEmpty ==
                  true
              ? (normalizedProfile['expression_prompt_answer'] as String?)
                  ?.trim()
              : cachedUser?.expressionPromptAnswer;
      normalizedProfile['expressionVibeTag'] =
          (normalizedProfile['expression_vibe_tag'] as String?)
                      ?.trim()
                      .isNotEmpty ==
                  true
              ? (normalizedProfile['expression_vibe_tag'] as String?)?.trim()
              : cachedUser?.expressionVibeTag;
      normalizedProfile['expressionShortPost'] =
          (normalizedProfile['expression_short_post'] as String?)
                      ?.trim()
                      .isNotEmpty ==
                  true
              ? (normalizedProfile['expression_short_post'] as String?)?.trim()
              : cachedUser?.expressionShortPost;
      normalizedProfile['activeIdentityMode'] =
          (normalizedProfile['active_identity_mode'] as String?) ??
              cachedUser?.activeIdentityMode.name ??
              'social';
      normalizedProfile['anonymousOverlayEnabled'] =
          (normalizedProfile['anonymous_overlay_enabled'] as bool?) ??
              cachedUser?.anonymousOverlayEnabled ??
              false;
      normalizedProfile['vibeLabel'] =
          (normalizedProfile['vibe_status'] as String?) ??
              cachedUser?.vibeLabel.name ??
              'oldSoul';
      normalizedProfile['verificationLevel'] =
          cachedUser?.verificationLevel.name ?? 'level0';
      normalizedProfile['trustScore'] = cachedUser?.trustScore ?? 70;
      normalizedProfile['riskLevel'] = cachedUser?.riskLevel.name ?? 'low';
      normalizedProfile['trustLastUpdated'] =
          cachedUser?.trustLastUpdated?.toIso8601String();
      normalizedProfile['showVerificationBadge'] =
          cachedUser?.showVerificationBadge ?? true;
      normalizedProfile['showTrustIndicator'] =
          cachedUser?.showTrustIndicator ?? true;
      normalizedProfile['allowScreenshots'] =
          cachedUser?.allowScreenshots ?? true;
      normalizedProfile['messageAutoDelete'] =
          cachedUser?.messageAutoDelete ?? false;
      normalizedProfile['profileVisibility'] =
          cachedUser?.profileVisibility.name ?? 'public';
      normalizedProfile['createdAt'] = DateTime.tryParse(
            normalizedProfile['createdAt']?.toString() ??
                normalizedProfile['created_at']?.toString() ??
                '',
          )?.toIso8601String() ??
          DateTime.now().toIso8601String();
      normalizedProfile['updatedAt'] = DateTime.tryParse(
            normalizedProfile['updatedAt']?.toString() ??
                normalizedProfile['updated_at']?.toString() ??
                '',
          )?.toIso8601String() ??
          DateTime.now().toIso8601String();
      _currentUser = model.User.fromJson(normalizedProfile);
      debugPrint(
        'AppProvider._syncCurrentUserFromSupabase loaded profile: '
        'id=${_currentUser?.id}, username=${_currentUser?.username}, bio=${_currentUser?.bio}',
      );
    } catch (e) {
      debugPrint('AppProvider._syncCurrentUserFromSupabase failed: $e');
      _currentUser = cachedUser;
      _hasPersistedIntent = cachedUser?.intents.isNotEmpty ?? false;
      _hasPersistedMood = cachedUser?.moodTags.isNotEmpty ?? false;
    }

    notifyListeners();
  }

  Future<void> refreshCurrentUserFromSupabase() async {
    await _syncCurrentUserFromSupabase();
    await _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final settings = AppSettingsService();

    _softModeEnabled =
        await settings.getSoftModeEnabled(userId: _currentUser?.id);
    _glowScaleUser =
        (await settings.getGlowScale(userId: _currentUser?.id)).clamp(0.0, 1.5);
    _creatorModeEnabled =
        await settings.getCreatorModeEnabled(userId: _currentUser?.id);
    _creatorApproved =
        await settings.getCreatorApproved(userId: _currentUser?.id);
    _creatorOnboardingComplete = await settings.getCreatorOnboardingComplete(
      userId: _currentUser?.id,
    );
    _hasAdvancedVerification = await settings.getHasAdvancedVerification(
      userId: _currentUser?.id,
    );
    _hasBackgroundVerification = await settings.getHasBackgroundVerification(
      userId: _currentUser?.id,
    );
    _hasLuxeInvite = await settings.getHasLuxeInvite(
      userId: _currentUser?.id,
    );
    _hasLuxeSubscription = await settings.getHasLuxeSubscription(
      userId: _currentUser?.id,
    );
    _showLivesInFeed =
        await settings.getShowLivesInFeed(userId: _currentUser?.id);
    _livesInFeedFrequency = await settings.getLivesInFeedFrequency(
      userId: _currentUser?.id,
    );
    _feedContentIntensity = await settings.getFeedContentIntensity(
      userId: _currentUser?.id,
    );
    _feedCreatorWeight = await settings.getFeedCreatorWeight(
      userId: _currentUser?.id,
    );
    _feedRomanticVisibility = await settings.getFeedRomanticVisibility(
      userId: _currentUser?.id,
    );
    _feedEmotionalSensitivity = await settings.getFeedEmotionalSensitivity(
      userId: _currentUser?.id,
    );
    _feedTabOrder = await settings.getFeedTabOrder(userId: _currentUser?.id);
    _feedDiscoveryBalance = await settings.getFeedDiscoveryBalance(
      userId: _currentUser?.id,
    );
    _feedMutedTopics =
        await settings.getFeedMutedTopics(userId: _currentUser?.id);
    _feedMutedMoods =
        await settings.getFeedMutedMoods(userId: _currentUser?.id);
    _smartFeedSwitchingEnabled = await settings.getSmartFeedSwitchingEnabled(
      userId: _currentUser?.id,
    );
    _moodAdaptiveUiEnabled = await settings.getMoodAdaptiveUiEnabled(
      userId: _currentUser?.id,
    );
    _transparencyExplainersEnabled =
        await settings.getTransparencyExplainersEnabled(
      userId: _currentUser?.id,
    );
    _lowEnergyFeedEnabled = await settings.getLowEnergyFeedEnabled(
      userId: _currentUser?.id,
    );
    _useMode = await settings.getUseMode(userId: _currentUser?.id);
    _fullSyncModeEnabled = await settings.getFullSyncModeEnabled(
      userId: _currentUser?.id,
    );
    _askVibeAtStartup = await settings.getAskVibeAtStartup(
      userId: _currentUser?.id,
    );
    _askIntentAtStartup = await settings.getAskIntentAtStartup(
      userId: _currentUser?.id,
    );
    _rememberMoodIntent = await settings.getRememberMoodIntent(
      userId: _currentUser?.id,
    );
    _appearanceMode = await settings.getAppearanceMode(
      userId: _currentUser?.id,
    );

    if (_useMode == 'dating') {
      _fullSyncModeEnabled = true;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final settings = AppSettingsService();

    try {
      _softModeGateCompleted = await settings.getSoftModeGateCompleted();

      await _syncCurrentUserFromSupabase();

      _authSub ??=
          SupabaseConfig.auth.onAuthStateChange.listen((AuthState data) async {
        await _syncCurrentUserFromSupabase();
        await _loadLocalSettings();
        notifyListeners();
      });

      await _loadLocalSettings();
    } catch (e) {
      debugPrint('AppProvider.initialize failed: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setUseMode(String value) async {
    _useMode = value;

    if (value == 'dating') {
      _fullSyncModeEnabled = true;
    }

    notifyListeners();

    await AppSettingsService().setUseMode(value, userId: _currentUser?.id);

    if (value == 'dating') {
      await AppSettingsService()
          .setFullSyncModeEnabled(true, userId: _currentUser?.id);
    }
  }

  Future<void> setFullSyncModeEnabled(bool enabled) async {
    _fullSyncModeEnabled = enabled;

    if (enabled) {
      _useMode = 'dating';
    }

    notifyListeners();

    await AppSettingsService()
        .setFullSyncModeEnabled(enabled, userId: _currentUser?.id);

    if (enabled) {
      await AppSettingsService().setUseMode('dating', userId: _currentUser?.id);
    }
  }

  Future<void> setAskVibeAtStartup(bool enabled) async {
    if (enabled == _askVibeAtStartup) return;
    _askVibeAtStartup = enabled;
    notifyListeners();
    await AppSettingsService().setAskVibeAtStartup(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setAskIntentAtStartup(bool enabled) async {
    if (enabled == _askIntentAtStartup) return;
    _askIntentAtStartup = enabled;
    notifyListeners();
    await AppSettingsService().setAskIntentAtStartup(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setRememberMoodIntent(bool enabled) async {
    if (enabled == _rememberMoodIntent) return;
    _rememberMoodIntent = enabled;
    notifyListeners();
    await AppSettingsService().setRememberMoodIntent(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setAppearanceMode(String mode) async {
    if (mode == _appearanceMode) return;
    _appearanceMode = mode;
    notifyListeners();
    await AppSettingsService().setAppearanceMode(
      mode,
      userId: _currentUser?.id,
    );
  }

  Future<void> completeSoftModeGate({required bool enabled}) async {
    final settings = AppSettingsService();
    _softModeGateCompleted = true;
    _softModeEnabled = enabled;
    notifyListeners();

    await settings.setSoftModeGateCompleted(true);
    await settings.setSoftModeEnabled(enabled, userId: _currentUser?.id);
  }

  Future<void> setSoftModeEnabled(bool enabled) async {
    _softModeEnabled = enabled;
    notifyListeners();
    await AppSettingsService()
        .setSoftModeEnabled(enabled, userId: _currentUser?.id);
  }

  Future<void> setGlowScaleUser(double value) async {
    final clamped = value.clamp(0.0, 1.5);

    if (clamped == _glowScaleUser) return;

    _glowScaleUser = clamped;
    notifyListeners();
    await AppSettingsService().setGlowScale(clamped, userId: _currentUser?.id);
  }

  Future<void> setCreatorModeEnabled(bool enabled) async {
    _creatorModeEnabled = enabled;
    notifyListeners();
    await AppSettingsService()
        .setCreatorModeEnabled(enabled, userId: _currentUser?.id);
  }

  Future<void> setCreatorApproved(bool approved) async {
    _creatorApproved = approved;
    notifyListeners();
    await AppSettingsService()
        .setCreatorApproved(approved, userId: _currentUser?.id);
  }

  Future<void> setCreatorOnboardingComplete(bool completed) async {
    _creatorOnboardingComplete = completed;
    notifyListeners();
    await AppSettingsService().setCreatorOnboardingComplete(
      completed,
      userId: _currentUser?.id,
    );
  }

  Future<void> setHasAdvancedVerification(bool enabled) async {
    _hasAdvancedVerification = enabled;
    notifyListeners();
    await AppSettingsService().setHasAdvancedVerification(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setHasBackgroundVerification(bool enabled) async {
    _hasBackgroundVerification = enabled;
    notifyListeners();
    await AppSettingsService().setHasBackgroundVerification(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setHasLuxeInvite(bool enabled) async {
    _hasLuxeInvite = enabled;
    notifyListeners();
    await AppSettingsService().setHasLuxeInvite(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setHasLuxeSubscription(bool enabled) async {
    _hasLuxeSubscription = enabled;
    notifyListeners();
    await AppSettingsService().setHasLuxeSubscription(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setShowLivesInFeed(bool enabled) async {
    _showLivesInFeed = enabled;
    notifyListeners();
    await AppSettingsService()
        .setShowLivesInFeed(enabled, userId: _currentUser?.id);
  }

  Future<void> setLivesInFeedFrequency(String value) async {
    _livesInFeedFrequency = value;
    notifyListeners();
    await AppSettingsService()
        .setLivesInFeedFrequency(value, userId: _currentUser?.id);
  }

  Future<void> setFeedContentIntensity(double value) async {
    final v = value.clamp(0.0, 1.0);

    if (v == _feedContentIntensity) return;

    _feedContentIntensity = v;
    notifyListeners();
    await AppSettingsService()
        .setFeedContentIntensity(v, userId: _currentUser?.id);
  }

  Future<void> setFeedCreatorWeight(double value) async {
    final v = value.clamp(0.0, 1.0);

    if (v == _feedCreatorWeight) return;

    _feedCreatorWeight = v;
    notifyListeners();
    await AppSettingsService()
        .setFeedCreatorWeight(v, userId: _currentUser?.id);
  }

  Future<void> setFeedRomanticVisibility(double value) async {
    final v = value.clamp(0.0, 1.0);

    if (v == _feedRomanticVisibility) return;

    _feedRomanticVisibility = v;
    notifyListeners();
    await AppSettingsService()
        .setFeedRomanticVisibility(v, userId: _currentUser?.id);
  }

  Future<void> setFeedEmotionalSensitivity(double value) async {
    final v = value.clamp(0.0, 1.0);

    if (v == _feedEmotionalSensitivity) return;

    _feedEmotionalSensitivity = v;
    notifyListeners();
    await AppSettingsService()
        .setFeedEmotionalSensitivity(v, userId: _currentUser?.id);
  }

  Future<void> setFeedTabOrder(List<String> order) async {
    if (listEquals(order, _feedTabOrder)) return;

    _feedTabOrder = List<String>.unmodifiable(order);
    notifyListeners();
    await AppSettingsService().setFeedTabOrder(order, userId: _currentUser?.id);
  }

  Future<void> setFeedDiscoveryBalance(double value) async {
    final v = value.clamp(0.0, 1.0);

    if (v == _feedDiscoveryBalance) return;

    _feedDiscoveryBalance = v;
    notifyListeners();
    await AppSettingsService()
        .setFeedDiscoveryBalance(v, userId: _currentUser?.id);
  }

  Future<void> setFeedMutedTopics(List<String> value) async {
    final next = value
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (listEquals(next, _feedMutedTopics)) return;

    _feedMutedTopics = next;
    notifyListeners();
    await AppSettingsService()
        .setFeedMutedTopics(next, userId: _currentUser?.id);
  }

  Future<void> setFeedMutedMoods(List<String> value) async {
    final next = value
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (listEquals(next, _feedMutedMoods)) return;

    _feedMutedMoods = next;
    notifyListeners();
    await AppSettingsService()
        .setFeedMutedMoods(next, userId: _currentUser?.id);
  }

  Future<void> setSmartFeedSwitchingEnabled(bool enabled) async {
    if (enabled == _smartFeedSwitchingEnabled) return;

    _smartFeedSwitchingEnabled = enabled;
    notifyListeners();
    await AppSettingsService()
        .setSmartFeedSwitchingEnabled(enabled, userId: _currentUser?.id);
  }

  Future<void> setMoodAdaptiveUiEnabled(bool enabled) async {
    if (enabled == _moodAdaptiveUiEnabled) return;

    _moodAdaptiveUiEnabled = enabled;
    notifyListeners();
    await AppSettingsService()
        .setMoodAdaptiveUiEnabled(enabled, userId: _currentUser?.id);
  }

  Future<void> setTransparencyExplainersEnabled(bool enabled) async {
    if (enabled == _transparencyExplainersEnabled) return;

    _transparencyExplainersEnabled = enabled;
    notifyListeners();
    await AppSettingsService().setTransparencyExplainersEnabled(
      enabled,
      userId: _currentUser?.id,
    );
  }

  Future<void> setLowEnergyFeedEnabled(bool enabled) async {
    if (enabled == _lowEnergyFeedEnabled) return;

    _lowEnergyFeedEnabled = enabled;

    if (enabled) {
      _feedContentIntensity = (_feedContentIntensity * 0.80).clamp(0.0, 1.0);
      _showLivesInFeed = false;
    }

    notifyListeners();

    final settings = AppSettingsService();
    await settings.setLowEnergyFeedEnabled(enabled, userId: _currentUser?.id);

    if (enabled) {
      await settings.setFeedContentIntensity(
        _feedContentIntensity,
        userId: _currentUser?.id,
      );
      await settings.setShowLivesInFeed(
        _showLivesInFeed,
        userId: _currentUser?.id,
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
