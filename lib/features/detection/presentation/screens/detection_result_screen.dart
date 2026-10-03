import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../widgets/detection_overlay_painter.dart';

class DetectionResultScreen extends StatefulWidget {
  final WeedDetectionResult result;
  final String fieldId;
  final String? scanId;

  const DetectionResultScreen({
    super.key,
    required this.result,
    required this.fieldId,
    this.scanId,
  });

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  bool _showFieldZones = false;

  @override
  Widget build(BuildContext context) {
    return _showFieldZones
        ? _FieldZonesScreen(
            result: widget.result,
            scanId: widget.scanId,
            onBack: () => setState(() => _showFieldZones = false),
          )
        : _AnalysisResultsScreen(
            result: widget.result,
            fieldId: widget.fieldId,
            scanId: widget.scanId,
            onViewFieldZones: () => setState(() => _showFieldZones = true),
          );
  }
}

// ─── Analysis Results Screen ──────────────────────────────────────────────────

class _AnalysisResultsScreen extends StatelessWidget {
  final WeedDetectionResult result;
  final String fieldId;
  final String? scanId;
  final VoidCallback onViewFieldZones;

  const _AnalysisResultsScreen({
    required this.result,
    required this.fieldId,
    required this.scanId,
    required this.onViewFieldZones,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.eco, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('WeedGuard AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Analysis Results',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 2),
                        const Text('Field scan completed successfully',
                            style: TextStyle(fontSize: 13, color: Color(0xFF5C5C5C))),
                      ],
                    ),
                  ),
                  // Image with bounding boxes
                  _ScannedImageSection(result: result),
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _StatsRow(result: result),
                  ),
                  // Detected weed types
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _DetectedWeedTypes(result: result),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onViewFieldZones,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: const Text('View Field Zones',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedImageSection extends StatelessWidget {
  final WeedDetectionResult result;
  const _ScannedImageSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 240,
          child: result.imagePath != null
              ? Image.file(File(result.imagePath!), fit: BoxFit.cover)
              : Container(
                  color: const Color(0xFF2E7D32),
                  child: const Center(child: Icon(Icons.image_outlined, size: 64, color: Colors.white38)),
                ),
        ),
        // Bounding boxes overlay
        if (result.detections.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: _LabeledOverlayPainter(detections: result.detections),
            ),
          ),
        // AI Analysis badge
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.eco, color: Color(0xFF1B5E20), size: 13),
                SizedBox(width: 4),
                Text('AI Analysis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WeedDetectionResult result;
  const _StatsRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final confidence = result.averageConfidence;
    final severity = result.severity;
    final severityColor = _severityColor(severity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Total weeds
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_florist, color: Color(0xFF1B5E20), size: 18),
                  SizedBox(width: 6),
                  Text('Total Weeds Detected', style: TextStyle(fontSize: 11, color: Color(0xFF5C5C5C))),
                ],
              ),
              const SizedBox(height: 4),
              Text('${result.weedCount}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), height: 1)),
              const SizedBox(height: 2),
              const Text('(across 1.2 ha)', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
        // Circular confidence
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(80, 80),
                painter: _CircularProgressPainter(value: confidence),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${(confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const Text('Avg. Confidence', style: TextStyle(fontSize: 8, color: Color(0xFF9E9E9E)), textAlign: TextAlign.center),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Infestation level
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.eco_outlined, color: Color(0xFF1B5E20), size: 16),
                SizedBox(width: 4),
                Text('Infestation Level', style: TextStyle(fontSize: 11, color: Color(0xFF5C5C5C))),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              severity.label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: severityColor),
            ),
          ],
        ),
      ],
    );
  }

  Color _severityColor(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.low: return AppColors.severityLow;
      case SeverityLevel.moderate: return AppColors.severityModerate;
      case SeverityLevel.high: return AppColors.severityHigh;
    }
  }
}

class _DetectedWeedTypes extends StatelessWidget {
  final WeedDetectionResult result;
  const _DetectedWeedTypes({required this.result});

  // Group detections by label
  Map<String, List<WeedDetection>> get _grouped {
    final map = <String, List<WeedDetection>>{};
    for (final d in result.detections) {
      map.putIfAbsent(d.label, () => []).add(d);
    }
    return map;
  }

  static const _weedMeta = {
    'Amaranthus': ('Amaranthus (Pigweed)', AppColors.severityHigh),
    'Lantana': ('Lantana', AppColors.severityModerate),
    'Cyperus': ('Cyperus (Nutgrass)', AppColors.severityModerate),
    'Crop': ('Crop (Non-weed)', AppColors.severityLow),
  };

  static const _fallbackColors = [
    AppColors.severityHigh,
    AppColors.severityModerate,
    AppColors.severityLow,
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    if (grouped.isEmpty) return const SizedBox.shrink();

    final entries = grouped.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detected Weed Types',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 12),
        ...List.generate(entries.length, (i) {
          final label = entries[i].key;
          final dets = entries[i].value;
          final avgConf = dets.map((d) => d.confidence).reduce((a, b) => a + b) / dets.length;
          final meta = _weedMeta[label];
          final displayName = meta?.$1 ?? label;
          final dotColor = meta?.$2 ?? _fallbackColors[i % _fallbackColors.length];
          final isLast = i == entries.length - 1;

          return Column(
            children: [
              _WeedTypeRow(
                label: displayName,
                count: dets.length,
                confidence: avgConf,
                dotColor: dotColor,
                isWeed: label != 'Crop',
              ),
              if (!isLast) const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          );
        }),
      ],
    );
  }
}

class _WeedTypeRow extends StatelessWidget {
  final String label;
  final int count;
  final double confidence;
  final Color dotColor;
  final bool isWeed;

  const _WeedTypeRow({
    required this.label,
    required this.count,
    required this.confidence,
    required this.dotColor,
    required this.isWeed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFE8F5E9),
            ),
            child: isWeed
                ? const Icon(Icons.grass, color: Color(0xFF2E7D32), size: 28)
                : const Icon(Icons.spa_outlined, color: Color(0xFF388E3C), size: 28),
          ),
          const SizedBox(width: 12),
          // Name and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(
                  '$count detected · ${(confidence * 100).toStringAsFixed(0)}% confidence',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
                ),
              ],
            ),
          ),
          // Severity dot
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E), size: 20),
        ],
      ),
    );
  }
}

// ─── Field Zones Screen ───────────────────────────────────────────────────────

class _FieldZonesScreen extends StatelessWidget {
  final WeedDetectionResult result;
  final String? scanId;
  final VoidCallback onBack;

  const _FieldZonesScreen({required this.result, this.scanId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final zones = result.zones.isNotEmpty ? result.zones : _mockZones;
    final priorityZone = result.priorityZone ?? zones
        .reduce((a, b) => a.weedCount >= b.weedCount ? a : b)
        .zoneLabel;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.eco, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('WeedGuard AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Field Zones',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                        SizedBox(height: 2),
                        Text('Priority areas based on weed concentration',
                            style: TextStyle(fontSize: 13, color: Color(0xFF5C5C5C))),
                      ],
                    ),
                  ),
                  // Zone map
                  _ZoneMapWidget(zones: zones),
                  // Legend
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        _LegendItem(color: AppColors.severityLow, label: 'Low'),
                        const SizedBox(width: 16),
                        _LegendItem(color: AppColors.severityModerate, label: 'Moderate'),
                        const SizedBox(width: 16),
                        _LegendItem(color: AppColors.severityHigh, label: 'High'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Priority zone banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PriorityZoneBanner(priorityZone: priorityZone),
                  ),
                  const SizedBox(height: 16),
                  // Zone-wise summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ZoneSummary(zones: zones),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Save Scan button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/history'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.save_alt_rounded, size: 20),
                  label: const Text('Save Scan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<FieldZoneAnalysis> get _mockZones => [
    const FieldZoneAnalysis(zoneId: 'a', zoneLabel: 'Zone A', severity: SeverityLevel.low, weedCount: 2, coveragePercent: 12),
    const FieldZoneAnalysis(zoneId: 'b', zoneLabel: 'Zone B', severity: SeverityLevel.high, weedCount: 6, coveragePercent: 35),
    const FieldZoneAnalysis(zoneId: 'c', zoneLabel: 'Zone C', severity: SeverityLevel.moderate, weedCount: 4, coveragePercent: 28),
    const FieldZoneAnalysis(zoneId: 'd', zoneLabel: 'Zone D', severity: SeverityLevel.low, weedCount: 1, coveragePercent: 15),
  ];
}

class _ZoneMapWidget extends StatelessWidget {
  final List<FieldZoneAnalysis> zones;
  const _ZoneMapWidget({required this.zones});

  Color _severityColor(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.low: return AppColors.severityLow;
      case SeverityLevel.moderate: return AppColors.severityModerate;
      case SeverityLevel.high: return AppColors.severityHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Arrange zones: top-left=A(low), top-right=B(high), bottom-left=C(moderate), bottom-right=D(low)
    final zoneMap = <String, FieldZoneAnalysis>{};
    for (final z in zones) {
      zoneMap[z.zoneLabel] = z;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF388E3C).withOpacity(0.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background aerial field color
          Container(color: const Color(0xFF4CAF50).withOpacity(0.4)),
          // 4 zone quadrants
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _ZoneCell(zone: zones.isNotEmpty ? zones[0] : null, label: 'Zone A', color: _severityColor(zones.isNotEmpty ? zones[0].severity : SeverityLevel.low)),
                    _ZoneCell(zone: zones.length > 1 ? zones[1] : null, label: 'Zone B', color: _severityColor(zones.length > 1 ? zones[1].severity : SeverityLevel.high)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    _ZoneCell(zone: zones.length > 2 ? zones[2] : null, label: 'Zone C', color: _severityColor(zones.length > 2 ? zones[2].severity : SeverityLevel.moderate)),
                    _ZoneCell(zone: zones.length > 3 ? zones[3] : null, label: 'Zone D', color: _severityColor(zones.length > 3 ? zones[3].severity : SeverityLevel.low)),
                  ],
                ),
              ),
            ],
          ),
          // North indicator
          Positioned(
            top: 10, right: 10,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
              child: const Icon(Icons.navigation, size: 16, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneCell extends StatelessWidget {
  final FieldZoneAnalysis? zone;
  final String label;
  final Color color;

  const _ZoneCell({this.zone, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final z = zone;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.55),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(z?.zoneLabel ?? label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(z?.severity.label ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5C5C5C))),
      ],
    );
  }
}

class _PriorityZoneBanner extends StatelessWidget {
  final String priorityZone;
  const _PriorityZoneBanner({required this.priorityZone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: Color(0xFFC62828), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Priority Zone',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC62828))),
                Text(priorityZone,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFC62828))),
                const SizedBox(height: 2),
                const Text('Highest detected weed concentration\nin this scan.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5C5C5C))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
        ],
      ),
    );
  }
}

class _ZoneSummary extends StatelessWidget {
  final List<FieldZoneAnalysis> zones;
  const _ZoneSummary({required this.zones});

  Color _severityColor(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.low: return AppColors.severityLow;
      case SeverityLevel.moderate: return AppColors.severityModerate;
      case SeverityLevel.high: return AppColors.severityHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Zone-wise Summary',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 10),
        ...zones.map((z) {
          final color = _severityColor(z.severity);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${z.zoneLabel} (${z.severity.label})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                ),
                Text(
                  '${z.weedCount} ${z.weedCount == 1 ? 'weed' : 'weeds'}  ·  ${z.coveragePercent.toStringAsFixed(0)}% area',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Custom painters ──────────────────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double value;
  const _CircularProgressPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * value, false,
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) => old.value != value;
}

class _LabeledOverlayPainter extends CustomPainter {
  final List<WeedDetection> detections;
  const _LabeledOverlayPainter({required this.detections});

  static const _labelColors = {
    'Amaranthus': Color(0xFFE53935),
    'Lantana': Color(0xFFF57F17),
    'Crop': Color(0xFF43A047),
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final color = _labelColors[d.label] ?? const Color(0xFFE53935);
      final rect = Rect.fromLTWH(
        d.boundingBox.x * size.width,
        d.boundingBox.y * size.height,
        d.boundingBox.width * size.width,
        d.boundingBox.height * size.height,
      );

      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0);

      final tp = TextPainter(
        text: TextSpan(
          text: d.label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(rect.left, rect.top - 20, tp.width + 10, 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
        Paint()..color = color..style = PaintingStyle.fill,
      );
      tp.paint(canvas, Offset(rect.left + 5, rect.top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _LabeledOverlayPainter old) => old.detections != detections;
}
