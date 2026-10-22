import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../shared/models/scan_model.dart';

class ZoneGridWidget extends StatelessWidget {
  final List<FieldZoneAnalysis> zones;
  const ZoneGridWidget({super.key, required this.zones});

  Color _severityColor(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.low: return AppColors.severityLow;
      case SeverityLevel.moderate: return AppColors.severityModerate;
      case SeverityLevel.high: return AppColors.severityHigh;
    }
  }

  IconData _severityIcon(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.low: return Icons.check_circle_outline;
      case SeverityLevel.moderate: return Icons.warning_amber_outlined;
      case SeverityLevel.high: return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: zones.length,
      itemBuilder: (_, i) {
        final z = zones[i];
        final color = _severityColor(z.severity);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(_severityIcon(z.severity), color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(z.zoneLabel, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                ],
              ),
              const SizedBox(height: 2),
              Text('${z.weedCount} weeds', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}
