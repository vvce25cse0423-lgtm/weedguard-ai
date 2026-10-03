import 'package:flutter/foundation.dart';
import 'detection_result_model.dart';

enum SeverityLevel { low, moderate, high }

extension SeverityLevelExtension on SeverityLevel {
  String get label {
    switch (this) {
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.moderate:
        return 'Moderate';
      case SeverityLevel.high:
        return 'High';
    }
  }

  String get dbValue {
    return name;
  }

  static SeverityLevel fromString(String value) {
    return SeverityLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SeverityLevel.low,
    );
  }
}

@immutable
class ScanModel {
  final String id;
  final String fieldId;
  final String userId;
  final String? imageUrl;
  final int weedCount;
  final double averageConfidence;
  final SeverityLevel severity;
  final String? priorityZone;
  final double? infestationScore;
  final bool isMockDetection;
  final List<FieldZoneAnalysis> zones;
  final DateTime createdAt;

  const ScanModel({
    required this.id,
    required this.fieldId,
    required this.userId,
    this.imageUrl,
    required this.weedCount,
    required this.averageConfidence,
    required this.severity,
    this.priorityZone,
    this.infestationScore,
    this.isMockDetection = false,
    this.zones = const [],
    required this.createdAt,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['field_zones'] as List<dynamic>? ?? [];
    return ScanModel(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String?,
      weedCount: json['weed_count'] as int? ?? 0,
      averageConfidence: (json['average_confidence'] as num?)?.toDouble() ?? 0.0,
      severity: SeverityLevelExtension.fromString(json['severity'] as String? ?? 'low'),
      priorityZone: json['priority_zone'] as String?,
      infestationScore: (json['infestation_score'] as num?)?.toDouble(),
      isMockDetection: json['is_mock_detection'] as bool? ?? false,
      zones: zonesJson.map((z) => FieldZoneAnalysis.fromJson(z as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'field_id': fieldId,
        'user_id': userId,
        'image_url': imageUrl,
        'weed_count': weedCount,
        'average_confidence': averageConfidence,
        'severity': severity.dbValue,
        'priority_zone': priorityZone,
        'infestation_score': infestationScore,
        'is_mock_detection': isMockDetection,
        'created_at': createdAt.toIso8601String(),
      };
}
