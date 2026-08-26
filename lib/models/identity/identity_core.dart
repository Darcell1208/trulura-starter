import 'package:flutter/foundation.dart';

/// Persistent identity fields backing Layer 1 (Identity) of the Aura model.
///
/// This is deliberately narrow: communication style, core values, and
/// relationship preferences only. Mood, energy, intent, and trust belong to
/// [AuraState] (Layer 2) and other systems, not here.
@immutable
class IdentityCore {
  final String userId;
  final String? communicationStyle;
  final List<String> coreValues;
  final String? relationshipPreferences;

  const IdentityCore({
    required this.userId,
    this.communicationStyle,
    this.coreValues = const [],
    this.relationshipPreferences,
  });

  factory IdentityCore.empty(String userId) => IdentityCore(userId: userId);

  factory IdentityCore.fromJson(Map<String, dynamic> json) => IdentityCore(
        userId: json['user_id'] as String,
        communicationStyle: json['communication_style'] as String?,
        coreValues: (json['core_values'] as List?)
                ?.whereType<Object>()
                .map((e) => e.toString())
                .toList(growable: false) ??
            const [],
        relationshipPreferences: json['relationship_preferences'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'communication_style': communicationStyle,
        'core_values': coreValues,
        'relationship_preferences': relationshipPreferences,
      };

  IdentityCore copyWith({
    String? communicationStyle,
    List<String>? coreValues,
    String? relationshipPreferences,
  }) =>
      IdentityCore(
        userId: userId,
        communicationStyle: communicationStyle ?? this.communicationStyle,
        coreValues: coreValues ?? this.coreValues,
        relationshipPreferences: relationshipPreferences ?? this.relationshipPreferences,
      );
}
