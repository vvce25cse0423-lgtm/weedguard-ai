# AI Integration Guide

## Architecture

WeedGuard uses a service abstraction to isolate the AI detection layer from the UI:

```dart
abstract class WeedDetectionService {
  Future<WeedDetectionResult> analyzeImage(File imageFile);
  bool get isMock;
}
```

## Current State: MockWeedDetectionService

`lib/shared/services/weed_detection_service.dart`

Generates synthetic detections to enable full UI development without the production model. Clearly flagged in the UI as "Demo detection".

## Production Integration

To replace mock with real YOLO-based inference:

1. Implement `RealWeedDetectionService`:

```dart
class RealWeedDetectionService implements WeedDetectionService {
  @override
  bool get isMock => false;

  @override
  Future<WeedDetectionResult> analyzeImage(File imageFile) async {
    // Option A: Call Supabase Edge Function that runs YOLO
    // Option B: Run ONNX model locally via flutter_pytorch or tflite
    // Return WeedDetectionResult with real bounding boxes
  }
}
```

2. Swap in `scanner_screen.dart`:

```dart
// Replace:
final _detectionService = MockWeedDetectionService();
// With:
final _detectionService = RealWeedDetectionService();
```

## Data Models

```dart
WeedDetectionResult {
  detections: List<WeedDetection>   // individual bounding boxes
  weedCount: int
  averageConfidence: double          // 0.0 – 1.0
  severity: SeverityLevel            // low / moderate / high
  infestationScore: double           // composite 0.0 – 1.0
  zones: List<FieldZoneAnalysis>     // 4-zone breakdown
  priorityZone: String?
  analyzedAt: DateTime
  isMockDetection: bool
}

WeedDetection {
  label: String       // weed type if model supports classification
  confidence: double
  boundingBox: BoundingBox  // x, y, width, height as image fractions (0–1)
}

FieldZoneAnalysis {
  zoneId: String        // zone_a, zone_b, zone_c, zone_d
  zoneLabel: String     // Zone A, Zone B, ...
  severity: SeverityLevel
  weedCount: int
  coveragePercent: double
}
```

## Severity Calculation

`lib/features/detection/domain/severity_calculator.dart`

```
infestationScore = (weedDensityScore × 0.7) + (averageConfidence × 0.3)

weedDensityScore = min(weedCount / 20, 1.0)

low      ≤ 0.30
moderate  0.31 – 0.60
high      > 0.60
```

Thresholds are configurable in `AppConstants`. These are prototype values — not validated agronomic standards.
