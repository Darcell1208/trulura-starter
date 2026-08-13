import 'package:trulura/models/user.dart';
import 'package:trulura/models/experience/experience_mode.dart';

enum TruPostContentType {
  social,
  romantic,
  support,
  creator,
  event,
  announcement,
  unknown;
}

extension TruPostContentTypeX on TruPostContentType {
  static TruPostContentType tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'social' => TruPostContentType.social,
      'romantic' || 'dating' => TruPostContentType.romantic,
      'support' || 'vent' => TruPostContentType.support,
      'creator' => TruPostContentType.creator,
      'event' => TruPostContentType.event,
      'announcement' => TruPostContentType.announcement,
      _ => TruPostContentType.unknown,
    };
  }
}

class Post {
  final String id;
  final String userId;
  final User? user;
  final String content;
  final String? caption;
  final String? imageUrl;
  final String type;
  final String? textStyle;
  final String? backgroundColorHex;
  final String? moodTag;
  final String privacy;
  final String category;
  final bool isAnonymous;

  /// The intent environment this post belongs to.
  ///
  /// This is the core bridge that makes Experience Modes feel like distinct
  /// worlds instead of just a UI filter.
  ///
  /// - When null (older data / backend rows without the column), the app will
  ///   infer a best-effort context.
  final TruExperienceMode? experienceMode;

  // Section 4 feed logic fields (backwards compatible; optional for older data)
  final TruPostContentType contentType;

  /// Which participation contexts this post is safe/valid to surface in.
  /// When empty, the app infers compatibility from `experienceMode`.
  final List<TruExperienceMode> modeCompatibility;

  /// 0–100 (higher = heavier/more intense). Used for sensitivity filtering.
  final int emotionalIntensityScore;

  /// Whether this post includes monetization prompts (subscriptions, ads, etc.).
  /// Vent should suppress these regardless of value.
  final bool isMonetized;

  /// Whether this post is currently boosted (paid or quest-based).
  final bool isBoosted;

  /// Whether the author is posting as a creator identity.
  final bool isCreatorContent;

  /// Optional event id or live linkage.
  final String? eventLinkage;

  /// Safety signals (local only for now): e.g. ['self_harm', 'nsfw', 'hate'].
  final List<String> safetyFlags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.userId,
    this.user,
    required this.content,
    this.caption,
    this.imageUrl,
    required this.type,
    this.textStyle,
    this.backgroundColorHex,
    this.moodTag,
    required this.privacy,
    required this.category,
    this.isAnonymous = false,
    this.experienceMode,
    this.contentType = TruPostContentType.unknown,
    this.modeCompatibility = const <TruExperienceMode>[],
    this.emotionalIntensityScore = 35,
    this.isMonetized = false,
    this.isBoosted = false,
    this.isCreatorContent = false,
    this.eventLinkage,
    this.safetyFlags = const <String>[],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  TruExperienceMode inferredExperienceMode() {
    if (experienceMode != null) return experienceMode!;
    final mood = (moodTag ?? '').trim().toLowerCase();
    final priv = (privacy).trim().toLowerCase();
    if (isAnonymous || priv == 'private' || mood.contains('sad') || mood.contains('anx') || mood.contains('grief')) return TruExperienceMode.vent;
    if (category.toLowerCase().contains('creator')) return TruExperienceMode.creator;
    return TruExperienceMode.social;
  }

  List<TruExperienceMode> inferredCompatibility() {
    if (modeCompatibility.isNotEmpty) return modeCompatibility;
    final inferred = inferredExperienceMode();
    return <TruExperienceMode>[inferred];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'user': user?.toJson(),
    'content': content,
    'caption': caption,
    'imageUrl': imageUrl,
    'type': type,
    'textStyle': textStyle,
    'backgroundColorHex': backgroundColorHex,
    'moodTag': moodTag,
    'privacy': privacy,
    'category': category,
    'isAnonymous': isAnonymous,
    'experienceMode': experienceMode?.name,
    'contentType': contentType.name,
    'modeCompatibility': modeCompatibility.map((m) => m.name).toList(),
    'emotionalIntensityScore': emotionalIntensityScore,
    'isMonetized': isMonetized,
    'isBoosted': isBoosted,
    'isCreatorContent': isCreatorContent,
    'eventLinkage': eventLinkage,
    'safetyFlags': safetyFlags,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'shareCount': shareCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    userId: json['userId'] as String,
    user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
    content: json['content'] as String,
    caption: json['caption'] as String?,
    imageUrl: json['imageUrl'] as String?,
    type: json['type'] as String,
    textStyle: json['textStyle'] as String?,
    backgroundColorHex: json['backgroundColorHex'] as String?,
    moodTag: json['moodTag'] as String?,
    privacy: json['privacy'] as String,
    category: json['category'] as String,
    isAnonymous: json['isAnonymous'] as bool? ?? false,
    experienceMode: TruExperienceModeX.tryParse(json['experienceMode'] as String?),
    contentType: TruPostContentTypeX.tryParse(json['contentType'] as String?),
    modeCompatibility: ((json['modeCompatibility'] as List?) ?? const [])
        .map((e) => TruExperienceModeX.tryParse(e?.toString()))
        .whereType<TruExperienceMode>()
        .toList(growable: false),
    emotionalIntensityScore: (json['emotionalIntensityScore'] as int? ?? 35).clamp(0, 100),
    isMonetized: json['isMonetized'] as bool? ?? false,
    isBoosted: json['isBoosted'] as bool? ?? false,
    isCreatorContent: json['isCreatorContent'] as bool? ?? false,
    eventLinkage: json['eventLinkage'] as String?,
    safetyFlags: ((json['safetyFlags'] as List?) ?? const []).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList(growable: false),
    likeCount: json['likeCount'] as int? ?? 0,
    commentCount: json['commentCount'] as int? ?? 0,
    shareCount: json['shareCount'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Post copyWith({
    String? id,
    String? userId,
    User? user,
    String? content,
    String? caption,
    String? imageUrl,
    String? type,
    String? textStyle,
    String? backgroundColorHex,
    String? moodTag,
    String? privacy,
    String? category,
    bool? isAnonymous,
    TruExperienceMode? experienceMode,
    TruPostContentType? contentType,
    List<TruExperienceMode>? modeCompatibility,
    int? emotionalIntensityScore,
    bool? isMonetized,
    bool? isBoosted,
    bool? isCreatorContent,
    String? eventLinkage,
    List<String>? safetyFlags,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Post(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    user: user ?? this.user,
    content: content ?? this.content,
    caption: caption ?? this.caption,
    imageUrl: imageUrl ?? this.imageUrl,
    type: type ?? this.type,
    textStyle: textStyle ?? this.textStyle,
    backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
    moodTag: moodTag ?? this.moodTag,
    privacy: privacy ?? this.privacy,
    category: category ?? this.category,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    experienceMode: experienceMode ?? this.experienceMode,
    contentType: contentType ?? this.contentType,
    modeCompatibility: modeCompatibility ?? this.modeCompatibility,
    emotionalIntensityScore: emotionalIntensityScore ?? this.emotionalIntensityScore,
    isMonetized: isMonetized ?? this.isMonetized,
    isBoosted: isBoosted ?? this.isBoosted,
    isCreatorContent: isCreatorContent ?? this.isCreatorContent,
    eventLinkage: eventLinkage ?? this.eventLinkage,
    safetyFlags: safetyFlags ?? this.safetyFlags,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    shareCount: shareCount ?? this.shareCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
