import 'package:flutter/material.dart';

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
      auraColor: AuraController.colorForMood(mood),
      vibeTags: AuraController.defaultTagsForMood(mood),
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

class AuraController extends ChangeNotifier {
  AuraState _state = AuraState.initial();

  AuraState get state => _state;
  Mood get mood => _state.mood;
  EnergyLevel get energyLevel => _state.energyLevel;
  Intent get intent => _state.intent;
  Color get auraColor => _state.auraColor;
  List<String> get vibeTags => _state.vibeTags;

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

  void updateMood(Mood newMood) {
    _state = _state.copyWith(
      mood: newMood,
      auraColor: colorForMood(newMood),
      vibeTags: defaultTagsForMood(newMood),
    );
    notifyListeners();
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
