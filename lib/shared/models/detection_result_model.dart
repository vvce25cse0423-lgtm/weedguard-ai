import 'package:flutter/foundation.dart';
import 'scan_model.dart';

@immutable
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'width': width, 'height': height};
}

@immutable
class WeedDetection {
  final String label;
  final double confidence;
  final BoundingBox boundingBox;

  const WeedDetection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  factory WeedDetection.fromJson(Map<String, dynamic> json) => WeedDetection(
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        boundingBox: BoundingBox.fromJson(json['bounding_box'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'bounding_box': boundingBox.toJson(),
      };
}

@immutable
class FieldZoneAnalysis {
  final String zoneId;
  final String zoneLabel;
  final SeverityLevel severity;
  final int weedCount;
  final double coveragePercent;

  const FieldZoneAnalysis({
    required this.zoneId,
    required this.zoneLabel,
    required this.severity,
    required this.weedCount,
    required this.coveragePercent,
  });

  factory FieldZoneAnalysis.fromJson(Map<String, dynamic> json) => FieldZoneAnalysis(
        zoneId: json['zone_id'] as String,
        zoneLabel: json['zone_label'] as String,
        severity: SeverityLevelExtension.fromString(json['severity'] as String),
        weedCount: json['weed_count'] as int,
        coveragePercent: (json['coverage_percent'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'zone_id': zoneId,
        'zone_label': zoneLabel,
        'severity': severity.dbValue,
        'weed_count': weedCount,
        'coverage_percent': coveragePercent,
      };
}

@immutable
class WeedDetectionResult {
  final String? imagePath;
  final String? imageUrl;
  final List<WeedDetection> detections;
  final int weedCount;
  final double averageConfidence;
  final SeverityLevel severity;
  final double infestationScore;
  final List<FieldZoneAnalysis> zones;
  final String? priorityZone;
  final DateTime analyzedAt;
  final bool isMockDetection;

  const WeedDetectionResult({
    this.imagePath,
    this.imageUrl,
    required this.detections,
    required this.weedCount,
    required this.averageConfidence,
    required this.severity,
    required this.infestationScore,
    required this.zones,
    this.priorityZone,
    required this.analyzedAt,
    this.isMockDetection = false,
  });
}
