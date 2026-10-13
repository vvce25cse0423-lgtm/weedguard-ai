import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

class RoiSavingsCard extends StatelessWidget {
  final int weedCount;
  final double averageConfidence;
  final double acreage; // in acres, default 1.0

  const RoiSavingsCard({
    super.key,
    required this.weedCount,
    required this.averageConfidence,
    this.acreage = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Economic calculations:
    final double infectionRatio = (weedCount / 20).clamp(0.15, 0.45);
    final double blanketHerbicideVolumeLiters = 2.0 * acreage;
    final double blanketCost = blanketHerbicideVolumeLiters * 950 + (acreage * 450);

    final double spotHerbicideVolumeLiters = (blanketHerbicideVolumeLiters * infectionRatio);
    final double spotCost = (blanketCost * (infectionRatio + 0.15));

    final double savingsAmount = (blanketCost - spotCost).clamp(400, 50000);
    final int savingsPercent = (((blanketCost - spotCost) / blanketCost) * 100).round().clamp(40, 85);
    final int waterSavedLiters = ((150 * acreage) * (1.0 - infectionRatio)).round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.savings_rounded, color: Colors.amberAccent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.get('precision_roi_savings'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amberAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$savingsPercent% ${l10n.get('roi_savings_badge')}',
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Savings Highlight
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${savingsAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.get('roi_saved_per_acre'),
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparison Table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('traditional_spray'),
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${blanketCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${blanketHerbicideVolumeLiters.toStringAsFixed(1)}L ${l10n.get('chemical')}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 38, color: Colors.white24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('weedguard_spot_spray'),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${spotCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${spotHerbicideVolumeLiters.toStringAsFixed(1)}L ${l10n.get('chemical')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Eco metrics
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: Colors.lightBlueAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                '$waterSavedLiters L ${l10n.get('water_saved_label')}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const Spacer(),
              const Icon(Icons.shield_outlined, color: Colors.lightGreenAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.get('less_soil_residue'),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
