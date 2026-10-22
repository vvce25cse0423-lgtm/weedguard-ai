import 'package:flutter_test/flutter_test.dart';
import 'package:weedguard/shared/models/scan_model.dart';

void main() {
  group('ScanModel', () {
    final json = {
      'id': 'abc123',
      'field_id': 'field1',
      'user_id': 'user1',
      'image_url': null,
      'weed_count': 7,
      'average_confidence': 0.88,
      'severity': 'moderate',
      'priority_zone': 'Zone B',
      'infestation_score': 0.52,
      'is_mock_detection': true,
      'field_zones': [],
      'created_at': '2024-06-01T10:30:00.000Z',
    };

    test('fromJson parses correctly', () {
      final scan = ScanModel.fromJson(json);
      expect(scan.id, 'abc123');
      expect(scan.weedCount, 7);
      expect(scan.severity, SeverityLevel.moderate);
      expect(scan.isMockDetection, true);
    });

    test('toJson round-trips severity', () {
      final scan = ScanModel.fromJson(json);
      final out = scan.toJson();
      expect(out['severity'], 'moderate');
    });
  });

  group('SeverityLevel extension', () {
    test('fromString low', () => expect(SeverityLevelExtension.fromString('low'), SeverityLevel.low));
    test('fromString moderate', () => expect(SeverityLevelExtension.fromString('moderate'), SeverityLevel.moderate));
    test('fromString high', () => expect(SeverityLevelExtension.fromString('high'), SeverityLevel.high));
    test('fromString unknown falls back to low', () => expect(SeverityLevelExtension.fromString('unknown'), SeverityLevel.low));
  });
}
