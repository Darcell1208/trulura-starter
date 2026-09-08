import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trulura/models/identity/identity_core.dart';
import 'package:trulura/services/identity_core_repository.dart';
import 'package:trulura/services/moodsync_service.dart';

enum Mood { reflective, flirty, calm, social, healing }

enum EnergyLevel { low, medium, high }

enum Intent { social, dating, healing, networking }

@immutable
class AuraState {
  final Mood mood;
  final EnergyLevel energyLevel;
  final Intent intent;
  final Color auraColor;
  final List<String> vibeTags;

  const AuraState({
    required this.mood,
    required this.energyLevel,
    required this.intent,
    required this.auraColor,
    required this.vibeTags,
  });

  factory AuraState.initial() {
    const mood = Mood.calm;
    return AuraState(
      mood: mood,
      energyLevel: EnergyLevel.medium,
      intent: Intent.social,
      auraColor: AuraStateController.colorForMood(mood),
      vibeTags: AuraStateController.defaultTagsForMood(mood),
    );
  }

  AuraState copyWith({
    Mood? mood,
    EnergyLevel? energyLevel,
    Intent? intent,
    Color? auraColor,
    List<String>? vibeTags,
  }) {
    return AuraState(
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
      intent: intent ?? this.intent,
      auraColor: auraColor ?? this.auraColor,
      vibeTags: vibeTags ?? this.vibeTags,
    );
  }
}

class AuraStateController extends ChangeNotifier {
  AuraStateController({
    IdentityCoreRepository? identityCoreRepository,
    MoodSyncService? moodSync,
  })  : _identityCoreRepository =
            identityCoreRepository ?? IdentityCoreRepository(),
        _moodSync = moodSync ?? MoodSyncService();

  AuraState _state = AuraState.initial();
  final IdentityCoreRepository _identityCoreRepository;
  final MoodSyncService _moodSync;
  IdentityCore? _identityCore;

  AuraState get state => _state;
  Mood get mood => _state.mood;
  EnergyLevel get energyLevel => _state.energyLevel;
  Intent get intent => _state.intent;
  Color get auraColor => _state.auraColor;
  List<String> get vibeTags => _state.vibeTags;

  /// The persistent identity baseline (Layer 1). Mood, energy, and intent
  /// above continue to layer on top of this rather than being derived from
  /// it. Null until [initialize] completes, or if the user has no saved
  /// identity core yet.
  IdentityCore? get identityCore => _identityCore;

  Future<void> initialize() async {
    _identityCore = await _identityCoreRepository.getForCurrentUser();

    // Hydrate mood from user_states so a returning user sees the mood they
    // last set rather than AuraState.initial()'s Mood.calm placeholder. A null
    // result means genuinely unset, offline, or signed out -- all cases where
    // the placeholder is the right thing to keep, so it is left alone.
    final stored = await _moodSync.currentMood();
    if (stored != null && stored != _state.mood) {
      _state = _state.copyWith(
        mood: stored,
        auraColor: colorForMood(stored),
        vibeTags: defaultTagsForMood(stored),
      );
    }

    notifyListeners();
  }

  static Color colorForMood(Mood mood) {
    return switch (mood) {
      Mood.reflective => const Color(0xFF6E7FBF),
      Mood.flirty => const Color(0xFFE45C96),
      Mood.calm => const Color(0xFF5DA8A3),
      Mood.social => const Color(0xFFFFB457),
      Mood.healing => const Color(0xFF7BC47F),
    };
  }

  static List<String> defaultTagsForMood(Mood mood) {
    return switch (mood) {
      Mood.reflective => const ['thoughtful', 'introspective'],
      Mood.flirty => const ['playful', 'spark'],
      Mood.calm => const ['steady', 'grounded'],
      Mood.social => const ['open', 'friendly'],
      Mood.healing => const ['gentle', 'restorative'],
    };
  }

  /// Sets the current mood and persists it.
  ///
  /// Stays synchronous and updates local state first so the aura colour and
  /// vibe tags change on the same frame as the tap; the write happens after.
  /// Making this async would push a network round trip in front of a purely
  /// visual state change.
  ///
  /// The write is intentionally not awaited by the caller. MoodSyncService
  /// swallows and logs its own failures and returns false when there is nowhere
  /// to write -- signed out, or Supabase unavailable -- so a failed persist
  /// leaves the UI on the newly chosen mood rather than snapping it back.
  /// Reverting would be worse: the user made a deliberate emotional
  /// declaration, and having it silently undo itself reads as the app
  /// overruling them.
  void updateMood(Mood newMood) {
    _state = _state.copyWith(
      mood: newMood,
      auraColor: colorForMood(newMood),
      vibeTags: defaultTagsForMood(newMood),
    );
    notifyListeners();

    unawaited(_persistMood(newMood));
  }

  Future<void> _persistMood(Mood mood) async {
    try {
      await _moodSync.recordMood(mood);
    } catch (e) {
      debugPrint('AuraStateController._persistMood failed: $e');
    }
  }

  void updateEnergy(EnergyLevel level) {
    _state = _state.copyWith(energyLevel: level);
    notifyListeners();
  }

  void updateIntent(Intent intent) {
    _state = _state.copyWith(intent: intent);
    notifyListeners();
  }
}
