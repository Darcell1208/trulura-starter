import 'package:flutter/foundation.dart';
import 'package:trulura/models/user.dart';

/// Per-identity-mode profile overrides.
///
/// This maps cleanly to your intended DB shape:
/// - `profiles` (base)
/// - `identity_modes` (active mode + per-mode enablement)
///
/// For MVP, we keep it local-first and only override what a user *chooses*.
@immutable
class TruIdentityProfile {
  final TruIdentityMode mode;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final TruProfileType profileType;
  final bool isActive;

  const TruIdentityProfile({
    required this.mode,
    this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.profileType = TruProfileType.social,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'displayName': displayName,
        'username': username,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'profileType': profileType.name,
        'isActive': isActive,
      };

  factory TruIdentityProfile.fromJson(Map<String, dynamic> json) => TruIdentityProfile(
        mode: TruIdentityModeX.tryParse(json['mode'] as String?) ?? TruIdentityMode.social,
        displayName: json['displayName'] as String?,
        username: json['username'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        profileType: TruProfileTypeX.tryParse(json['profileType'] as String?) ?? TruProfileType.social,
        isActive: (json['isActive'] as bool?) ?? true,
      );

  TruIdentityProfile copyWith({
    TruIdentityMode? mode,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    TruProfileType? profileType,
    bool? isActive,
  }) =>
      TruIdentityProfile(
        mode: mode ?? this.mode,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        profileType: profileType ?? this.profileType,
        isActive: isActive ?? this.isActive,
      );
}

enum TruProfileType { social, dating, creator, luxe }

extension TruProfileTypeX on TruProfileType {
  static TruProfileType? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in TruProfileType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label {
    switch (this) {
      case TruProfileType.social:
        return 'Social';
      case TruProfileType.dating:
        return 'Dating';
      case TruProfileType.creator:
        return 'Creator';
      case TruProfileType.luxe:
        return 'Luxe';
    }
  }
}
