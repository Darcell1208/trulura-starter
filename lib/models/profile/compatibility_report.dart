import 'package:flutter/foundation.dart';
import 'package:trulura/models/user.dart';

@immutable
class TruAttractionMap {
  final int emotional;
  final int intellectual;
  final int visual;
  final int cultural;
  final int lifestyle;

  const TruAttractionMap({required this.emotional, required this.intellectual, required this.visual, required this.cultural, required this.lifestyle});

  Map<String, dynamic> toJson() => {
        'emotional': emotional,
        'intellectual': intellectual,
        'visual': visual,
        'cultural': cultural,
        'lifestyle': lifestyle,
      };

  factory TruAttractionMap.fromJson(Map<String, dynamic> json) => TruAttractionMap(
        emotional: (json['emotional'] as num?)?.round() ?? 50,
        intellectual: (json['intellectual'] as num?)?.round() ?? 50,
        visual: (json['visual'] as num?)?.round() ?? 50,
        cultural: (json['cultural'] as num?)?.round() ?? 50,
        lifestyle: (json['lifestyle'] as num?)?.round() ?? 50,
      );
}

@immutable
class TruCompatibilityDimension {
  final String key;
  final String title;
  final int score;
  final String insight;

  const TruCompatibilityDimension({required this.key, required this.title, required this.score, required this.insight});

  Map<String, dynamic> toJson() => {'key': key, 'title': title, 'score': score, 'insight': insight};

  factory TruCompatibilityDimension.fromJson(Map<String, dynamic> json) => TruCompatibilityDimension(
        key: (json['key'] as String?) ?? 'unknown',
        title: (json['title'] as String?) ?? 'Unknown',
        score: (json['score'] as num?)?.round() ?? 70,
        insight: (json['insight'] as String?) ?? '',
      );
}

@immutable
class TruCompatibilityReport {
  final String viewerUserId;
  final TruIdentityMode context;
  final int overall;
  final TruAttractionMap attraction;
  final List<TruCompatibilityDimension> dimensions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruCompatibilityReport({
    required this.viewerUserId,
    required this.context,
    required this.overall,
    required this.attraction,
    required this.dimensions,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'viewerUserId': viewerUserId,
        'context': context.name,
        'overall': overall,
        'attraction': attraction.toJson(),
        'dimensions': dimensions.map((d) => d.toJson()).toList(growable: false),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruCompatibilityReport.fromJson(Map<String, dynamic> json) => TruCompatibilityReport(
        viewerUserId: (json['viewerUserId'] as String?) ?? '',
        context: TruIdentityModeX.tryParse(json['context'] as String?) ?? TruIdentityMode.social,
        overall: (json['overall'] as num?)?.round() ?? 72,
        attraction: TruAttractionMap.fromJson((json['attraction'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{}),
        dimensions: ((json['dimensions'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => TruCompatibilityDimension.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      );
}
