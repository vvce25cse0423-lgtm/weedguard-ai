import 'package:flutter_test/flutter_test.dart';
import 'package:weedguard/features/detection/domain/severity_calculator.dart';
import 'package:weedguard/shared/models/scan_model.dart';

void main() {
  group('SeverityCalculator', () {
    test('low score returns low severity', () {
      final s = SeverityCalculator.fromScore(0.1);
      expect(s, SeverityLevel.low);
    });

    test('moderate score returns moderate severity', () {
      final s = SeverityCalculator.fromScore(0.45);
      expect(s, SeverityLevel.moderate);
    });

    test('high score returns high severity', () {
      final s = SeverityCalculator.fromScore(0.75);
      expect(s, SeverityLevel.high);
    });

    test('zero weeds yields low severity', () {
      final score = SeverityCalculator.computeScore(0, 0.0);
      expect(SeverityCalculator.fromScore(score), SeverityLevel.low);
    });

    test('high weed count yields high severity', () {
      final score = SeverityCalculator.computeScore(20, 0.95);
      expect(SeverityCalculator.fromScore(score), SeverityLevel.high);
    });

    test('explain returns non-empty string', () {
      final e = SeverityCalculator.explain(5, 0.8);
      expect(e.isNotEmpty, true);
    });
  });
}
