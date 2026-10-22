import '../../../shared/models/scan_model.dart';
import '../../../core/constants/app_constants.dart';

class SeverityCalculator {
  static SeverityLevel fromScore(double score) {
    if (score <= AppConstants.severityLowMax) return SeverityLevel.low;
    if (score <= AppConstants.severityModerateMax) return SeverityLevel.moderate;
    return SeverityLevel.high;
  }

  static double computeScore(int weedCount, double avgConfidence) {
    final density = (weedCount / 20.0).clamp(0.0, 1.0);
    return (density * 0.7 + avgConfidence * 0.3).clamp(0.0, 1.0);
  }

  static String explain(int weedCount, double avgConfidence) {
    final score = computeScore(weedCount, avgConfidence);
    final level = fromScore(score);
    return switch (level) {
      SeverityLevel.low => 'Weed density is low across the scanned area. Routine monitoring is advised.',
      SeverityLevel.moderate => 'Moderate weed presence detected. Consider targeted intervention in priority zones.',
      SeverityLevel.high => 'High weed density detected. Prompt attention to priority zones is recommended.',
    };
  }
}
