import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:weedguard/shared/services/weed_detection_service.dart';

void main() {
  group('MockWeedDetectionService', () {
    late MockWeedDetectionService service;

    setUp(() => service = MockWeedDetectionService());

    test('isMock is true', () => expect(service.isMock, true));

    test('analyzeImage returns result with valid weed count', () async {
      // Use a temp file to simulate an image
      final tmpDir = Directory.systemTemp;
      final testFile = File('${tmpDir.path}/test_image.jpg');
      testFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG magic bytes

      final result = await service.analyzeImage(testFile);

      expect(result.weedCount, greaterThanOrEqualTo(0));
      expect(result.averageConfidence, inInclusiveRange(0.0, 1.0));
      expect(result.isMockDetection, true);
      expect(result.zones.length, 4);

      testFile.deleteSync();
    });

    test('zones cover all four quadrants', () async {
      final tmpDir = Directory.systemTemp;
      final testFile = File('${tmpDir.path}/test_image2.jpg');
      testFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      final result = await service.analyzeImage(testFile);
      final zoneLabels = result.zones.map((z) => z.zoneLabel).toList();
      expect(zoneLabels.contains('Zone A'), true);
      expect(zoneLabels.contains('Zone D'), true);

      testFile.deleteSync();
    });
  });
}
