import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

class ResistanceTrackerWidget extends StatelessWidget {
  final int baselineWeedCount;
  final int currentWeedCount;
  final int daysAfterTreatment;

  const ResistanceTrackerWidget({
    super.key,
    required this.baselineWeedCount,
    required this.currentWeedCount,
    this.daysAfterTreatment = 7,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final int safeBaseline = baselineWeedCount > 0 ? baselineWeedCount : (currentWeedCount + 6);
    final int safeCurrent = currentWeedCount;
    final int killedWeeds = (safeBaseline - safeCurrent).clamp(0, safeBaseline);
    final double mortalityRate = (killedWeeds / safeBaseline).clamp(0.0, 1.0);
    final int mortalityPercent = (mortalityRate * 100).round();

    final bool isResistant = daysAfterTreatment >= 7 && mortalityPercent < 45;

    final String daySuffix = l10n.locale.languageCode == 'kn' ? 'ನೇ ದಿನ' : (l10n.locale.languageCode == 'hi' ? 'दिन $daysAfterTreatment' : 'Day $daysAfterTreatment');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isResistant ? const Color(0xFFFFF3E0) : const Color(0xFFF9FBE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResistant ? Colors.deepOrange.shade300 : const Color(0xFFC5E1A5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isResistant ? Colors.deepOrange.shade100 : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isResistant ? Icons.warning_amber_rounded : Icons.timeline_rounded,
                  color: isResistant ? Colors.deepOrange.shade800 : const Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isResistant
                          ? l10n.get('herbicide_resistance_warning')
                          : l10n.get('post_spray_tracker'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isResistant ? Colors.deepOrange.shade900 : const Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      '$daySuffix ${l10n.get('followup_audit')}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isResistant ? Colors.deepOrange.shade800 : const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$mortalityPercent% ${l10n.get('eradicated_badge')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: mortalityRate,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isResistant ? Colors.deepOrange : const Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Counts comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineStep(
                l10n.get('initial_scan'),
                '$safeBaseline ${l10n.weedCol}',
                Icons.camera_alt_outlined,
              ),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              _buildTimelineStep(
                l10n.get('rescan'),
                '$safeCurrent ${l10n.get('weeds_remaining')}',
                Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Advisory message
          if (isResistant)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.report_problem_outlined, color: Colors.deepOrange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.get('resistance_alert_msg'),
                      style: TextStyle(fontSize: 11, color: Colors.deepOrange.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.get('efficacy_success_msg'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, String count, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
