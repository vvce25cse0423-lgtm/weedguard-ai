import 'package:flutter/material.dart';
import 'package:weedguard/core/services/notification_service.dart';
import 'package:weedguard/features/spray_window/data/spray_window_service.dart';
import 'package:weedguard/core/l10n/app_localizations.dart';

class SprayWindowDialog extends StatelessWidget {
  final double windSpeed;
  final double temperature;
  final int humidity;
  final int rainChance;

  const SprayWindowDialog({
    super.key,
    this.windSpeed = 6.8,
    this.temperature = 26.5,
    this.humidity = 62,
    this.rainChance = 12,
  });

  static Future<void> show(BuildContext context, {
    double windSpeed = 6.8,
    double temperature = 26.5,
    int humidity = 62,
    int rainChance = 12,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SprayWindowDialog(
        windSpeed: windSpeed,
        temperature: temperature,
        humidity: humidity,
        rainChance: rainChance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final analysis = SprayWindowService.calculateSuitability(
      windSpeed: windSpeed,
      temperature: temperature,
      humidity: humidity,
      rainChance: rainChance,
    );

    Color themeColor;
    IconData statusIcon;
    String statusTitle;
    String description;

    switch (analysis.suitability) {
      case SpraySuitability.optimal:
        themeColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_outline;
        statusTitle = l10n.sprayOptimalTitle;
        description = l10n.sprayOptimalDesc;
        break;
      case SpraySuitability.caution:
        themeColor = Colors.orange.shade800;
        statusIcon = Icons.warning_amber_rounded;
        statusTitle = l10n.sprayCautionTitle;
        description = l10n.sprayCautionDesc;
        break;
      case SpraySuitability.dangerous:
        themeColor = Colors.red.shade700;
        statusIcon = Icons.cancel_outlined;
        statusTitle = l10n.sprayDangerousTitle;
        description = l10n.sprayDangerousDesc;
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.wb_twilight_rounded, color: themeColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sprayDialogTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      l10n.sprayDialogSubtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Suitability Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: themeColor.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: themeColor, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${analysis.sprayScore}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Telemetry Grid
          Row(
            children: [
              _buildMetricTile(l10n.windSpeed, '${analysis.windSpeedKmh} km/h', Icons.air,
                  analysis.windSpeedKmh < 12 ? Colors.green.shade700 : Colors.red.shade700),
              const SizedBox(width: 8),
              _buildMetricTile(l10n.temperature, '${analysis.temperatureC}°C', Icons.thermostat,
                  analysis.temperatureC < 30 ? Colors.green.shade700 : Colors.orange.shade700),
              const SizedBox(width: 8),
              _buildMetricTile(l10n.rainRisk, '${analysis.rainProbability}%', Icons.umbrella,
                  analysis.rainProbability < 20 ? Colors.green.shade700 : Colors.red.shade700),
              const SizedBox(width: 8),
              _buildMetricTile(l10n.humidity, '${analysis.humidityPercent}%', Icons.water_drop,
                  Colors.blue.shade700),
            ],
          ),
          const SizedBox(height: 16),

          // Recommended Window
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC5E1A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFF33691E), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.sprayGoldenHour,
                    style: const TextStyle(
                      color: Color(0xFF33691E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Schedule Notification Action
          ElevatedButton.icon(
            onPressed: () async {
              await NotificationService.showNotification(
                title: '⏰ ${l10n.sprayReminderActive}',
                body: '${l10n.sprayGoldenHour}. ${l10n.windSpeed}: ${analysis.windSpeedKmh} km/h.',
                category: 'spray_window',
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.sprayReminderScheduled),
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                );
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: Text(l10n.setSprayAlert),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
