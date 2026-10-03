import 'dart:io';
import 'dart:math';
import '../models/detection_result_model.dart';
import '../models/scan_model.dart';
import '../../core/constants/app_constants.dart';

/// Abstract contract for weed detection.
/// Replace MockWeedDetectionService with RealWeedDetectionService
/// once the YOLO-based model is ready.
abstract class WeedDetectionService {
  Future<WeedDetectionResult> analyzeImage(File imageFile);
  bool get isMock;
}

/// Mock implementation for development and demo purposes.
/// Returns synthetic detections to allow full UI development
/// without the production model.
class MockWeedDetectionService implements WeedDetectionService {
  final Random _random = Random();

  @override
  bool get isMock => true;

  @override
  Future<WeedDetectionResult> analyzeImage(File imageFile) async {
    // Simulate realistic analysis latency
    await Future.delayed(const Duration(milliseconds: 2800));

    final weedCount = 4 + _random.nextInt(14);
    final detections = _generateMockDetections(weedCount);
    final zones = _generateMockZones(detections);
    final avgConfidence = detections.isEmpty
        ? 0.0
        : detections.map((d) => d.confidence).reduce((a, b) => a + b) / detections.length;
    final score = _calculateInfestationScore(weedCount, avgConfidence);
    final severity = _scoreToSeverity(score);
    final priorityZone = zones.isEmpty
        ? null
        : zones.reduce((a, b) => a.weedCount > b.weedCount ? a : b).zoneLabel;

    return WeedDetectionResult(
      imagePath: imageFile.path,
      detections: detections,
      weedCount: weedCount,
      averageConfidence: avgConfidence,
      severity: severity,
      infestationScore: score,
      zones: zones,
      priorityZone: priorityZone,
      analyzedAt: DateTime.now(),
      isMockDetection: true,
    );
  }

  List<WeedDetection> _generateMockDetections(int count) {
    const labels = [
      'Broadleaf weed',
      'Grass weed',
      'Sedge',
      'Creeping plant',
      'Unidentified weed',
    ];
    return List.generate(count, (i) {
      final x = _random.nextDouble() * 0.7;
      final y = _random.nextDouble() * 0.7;
      return WeedDetection(
        label: labels[_random.nextInt(labels.length)],
        confidence: 0.72 + _random.nextDouble() * 0.25,
        boundingBox: BoundingBox(
          x: x,
          y: y,
          width: 0.05 + _random.nextDouble() * 0.12,
          height: 0.05 + _random.nextDouble() * 0.12,
        ),
      );
    });
  }

  List<FieldZoneAnalysis> _generateMockZones(List<WeedDetection> detections) {
    const zoneLabels = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];
    final perZone = [0, 0, 0, 0];
    for (final d in detections) {
      final zoneIndex = _assignZone(d.boundingBox.x, d.boundingBox.y);
      perZone[zoneIndex]++;
    }
    return List.generate(4, (i) {
      final count = perZone[i];
      final coverage = count * (2.5 + _random.nextDouble() * 5);
      return FieldZoneAnalysis(
        zoneId: 'zone_${String.fromCharCode(97 + i)}',
        zoneLabel: zoneLabels[i],
        severity: _scoreToSeverity(_countToScore(count)),
        weedCount: count,
        coveragePercent: coverage.clamp(0, 100),
      );
    });
  }

  int _assignZone(double x, double y) {
    if (x < 0.5 && y < 0.5) return 0;
    if (x >= 0.5 && y < 0.5) return 1;
    if (x < 0.5 && y >= 0.5) return 2;
    return 3;
  }

  double _calculateInfestationScore(int count, double confidence) {
    final densityScore = (count / 20).clamp(0.0, 1.0);
    return (densityScore * 0.7 + confidence * 0.3).clamp(0.0, 1.0);
  }

  double _countToScore(int count) => (count / 8).clamp(0.0, 1.0);

  SeverityLevel _scoreToSeverity(double score) {
    if (score <= AppConstants.severityLowMax) return SeverityLevel.low;
    if (score <= AppConstants.severityModerateMax) return SeverityLevel.moderate;
    return SeverityLevel.high;
  }
}

/// Placeholder for production YOLO-based detection service.
/// Implement this class once the model endpoint is available.
///
/// class RealWeedDetectionService implements WeedDetectionService {
///   @override bool get isMock => false;
///   @override Future<WeedDetectionResult> analyzeImage(File imageFile) async {
///     // Call Supabase Edge Function or local ONNX model
///     throw UnimplementedError('Production model not integrated yet.');
///   }
/// }
