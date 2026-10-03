import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/scan_model.dart';

class SeverityChip extends StatelessWidget {
  final SeverityLevel severity;
  final bool small;
  const SeverityChip({super.key, required this.severity, this.small = false});

  Color get _color {
    switch (severity) {
      case SeverityLevel.low: return AppColors.severityLow;
      case SeverityLevel.moderate: return AppColors.severityModerate;
      case SeverityLevel.high: return AppColors.severityHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
          color: _color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
