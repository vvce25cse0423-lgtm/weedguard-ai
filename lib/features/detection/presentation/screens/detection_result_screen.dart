import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../widgets/detection_overlay_painter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../history/presentation/screens/scan_history_screen.dart';


class DetectionResultScreen extends ConsumerStatefulWidget {
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
  ConsumerState<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends ConsumerState<DetectionResultScreen> {
  bool _showFieldZones = false;
  bool _scanSaved = false;

  Future<void> _saveAndGoHistory() async {
    // If scan wasn't saved yet (scanId is null/empty), save it now
    if ((widget.scanId == null || widget.scanId!.isEmpty) && !_scanSaved) {
      setState(() => _scanSaved = true);
      try {
        final scanRepo = ScanRepository(Supabase.instance.client);
        await scanRepo.saveScan(
          fieldId: widget.fieldId.isEmpty ? null : widget.fieldId,
          result: widget.result,
          imageUrl: widget.result.imageUrl,
        );
      } catch (_) {
        // best effort
      }
    }
    ref.invalidate(dashboardScansProvider);
    ref.invalidate(scanHistoryProvider);
    if (mounted) context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    return _showFieldZones
        ? _FieldZonesScreen(
            result: widget.result,
            scanId: widget.scanId,
            onBack: () => setState(() => _showFieldZones = false),
            onSaveScan: _saveAndGoHistory,
          )
        : _AnalysisResultsScreen(
            result: widget.result,
            fieldId: widget.fieldId,
            scanId: widget.scanId,
            onViewFieldZones: () => setState(() => _showFieldZones = true),
            onSaveScan: _saveAndGoHistory,
          );
  }
}

// ─── Analysis Results Screen ──────────────────────────────────────────────────

class _AnalysisResultsScreen extends StatelessWidget {
  final WeedDetectionResult result;
  final String fieldId;
  final String? scanId;
  final VoidCallback onViewFieldZones;
  final VoidCallback onSaveScan;

  const _AnalysisResultsScreen({
    required this.result,
    required this.fieldId,
    required this.scanId,
    required this.onViewFieldZones,
    required this.onSaveScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            Text(AppLocalizations.of(context).appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
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
                        Text(AppLocalizations.of(context).analysisResults,
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
                  const SizedBox(height: 20),
                  // Herbicide recommendations
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _HerbicideRecommendations(result: result),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: onViewFieldZones,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).viewFieldZones,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: onSaveScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.save_alt_rounded, size: 18),
                        label: const Text('Save Scan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
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

  static const _cropKeywords = ['maize', 'rice', 'wheat', 'soybean', 'cotton', 'corn',
    'sugarcane', 'barley', 'sorghum', 'sunflower', 'tomato', 'potato', 'crop'];

  bool _isCrop(String label) {
    final lower = label.toLowerCase();
    return _cropKeywords.any((k) => lower.contains(k));
  }

  Map<String, List<WeedDetection>> _groupDetections(List<WeedDetection> dets) {
    final map = <String, List<WeedDetection>>{};
    for (final d in dets) {
      map.putIfAbsent(d.label, () => []).add(d);
    }
    return map;
  }

  static const _severityColors = [
    Color(0xFFE53935),
    Color(0xFFF57F17),
    Color(0xFF43A047),
    Color(0xFF1565C0),
  ];

  @override
  Widget build(BuildContext context) {
    final crops = result.detections.where((d) => _isCrop(d.label)).toList();
    final weeds = result.detections.where((d) => !_isCrop(d.label)).toList();
    final cropGrouped = _groupDetections(crops);
    final weedGrouped = _groupDetections(weeds);

    if (crops.isEmpty && weeds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── CROP IDENTIFIED ──
        if (cropGrouped.isNotEmpty) ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.spa, color: Color(0xFF2E7D32), size: 14),
                const SizedBox(width: 5),
                Text(AppLocalizations.of(context).cropIdentified, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              children: cropGrouped.entries.toList().asMap().entries.map((e) {
                final i = e.key;
                final label = e.value.key;
                final dets = e.value.value;
                final avgConf = dets.map((d) => d.confidence).reduce((a, b) => a + b) / dets.length;
                final isLast = i == cropGrouped.length - 1;
                return Column(children: [
                  _PlantRow(label: label, count: dets.length, confidence: avgConf, isCrop: true, accentColor: const Color(0xFF2E7D32)),
                  if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFDCEEDC)),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── WEEDS IDENTIFIED ──
        if (weedGrouped.isNotEmpty) ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.grass, color: Color(0xFFC62828), size: 14),
                const SizedBox(width: 5),
                Text(AppLocalizations.of(context).weedsIdentified, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC62828))),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Column(
              children: weedGrouped.entries.toList().asMap().entries.map((e) {
                final i = e.key;
                final label = e.value.key;
                final dets = e.value.value;
                final avgConf = dets.map((d) => d.confidence).reduce((a, b) => a + b) / dets.length;
                final isLast = i == weedGrouped.length - 1;
                final color = _severityColors[i % _severityColors.length];
                return Column(children: [
                  _PlantRow(label: label, count: dets.length, confidence: avgConf, isCrop: false, accentColor: color),
                  if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),
                ]);
              }).toList(),
            ),
          ),
        ],

        if (weeds.isEmpty && crops.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 8),
              Text('No weeds detected in this scan.', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ],
    );
  }
}

class _PlantRow extends StatelessWidget {
  final String label;
  final int count;
  final double confidence;
  final bool isCrop;
  final Color accentColor;

  const _PlantRow({
    required this.label,
    required this.count,
    required this.confidence,
    required this.isCrop,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accentColor.withOpacity(0.12),
            ),
            child: Icon(
              isCrop ? Icons.spa_outlined : Icons.grass,
              color: accentColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(
                  '$count ${count == 1 ? 'instance' : 'instances'} · ${(confidence * 100).toStringAsFixed(0)}% ${AppLocalizations.of(context).confidence}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCrop ? 'Crop' : 'Weed',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Herbicide Recommendations ───────────────────────────────────────────────

class _HerbicideRecommendations extends StatelessWidget {
  final WeedDetectionResult result;
  const _HerbicideRecommendations({required this.result});

  static const _cropKeywords = ['maize', 'rice', 'wheat', 'soybean', 'cotton', 'corn',
    'sugarcane', 'barley', 'sorghum', 'sunflower', 'tomato', 'potato', 'zea', 'oryza',
    'triticum', 'glycine', 'gossypium', 'crop'];

  bool _isCrop(String label) {
    final lower = label.toLowerCase();
    return _cropKeywords.any((k) => lower.contains(k));
  }

  static const Map<String, _HerbicideInfo> _herbicideMap = {
    'amaranthus': _HerbicideInfo('Atrazine 50WP', '2.0 kg/ha', 'Pre & post-emergent', '0xFF1565C0'),
    'cyperus': _HerbicideInfo('Halosulfuron-methyl', '67 g/ha', 'Post-emergent', '0xFF6A1B9A'),
    'digitaria': _HerbicideInfo('Quizalofop-ethyl', '1.0 L/ha', 'Post-emergent', '0xFF00695C'),
    'convolvulus': _HerbicideInfo('2,4-D Amine', '1.5 L/ha', 'Post-emergent', '0xFFE65100'),
    'echinochloa': _HerbicideInfo('Butachlor 50EC', '1.5 L/ha', 'Pre-emergent', '0xFF1565C0'),
    'lantana': _HerbicideInfo('Triclopyr', '3.0 L/ha', 'Post-emergent', '0xFF6A1B9A'),
    'parthenium': _HerbicideInfo('Metribuzin', '0.5 kg/ha', 'Pre & post-emergent', '0xFF4E342E'),
    'chenopodium': _HerbicideInfo('Pendimethalin', '1.0 kg/ha', 'Pre-emergent', '0xFF00695C'),
    'oxalis': _HerbicideInfo('Fluroxypyr', '1.0 L/ha', 'Post-emergent', '0xFFE65100'),
    'portulaca': _HerbicideInfo('Glyphosate 41%', '2.5 L/ha', 'Post-emergent', '0xFF558B2F'),
  };

  _HerbicideInfo _getHerbicide(String weedName) {
    final lower = weedName.toLowerCase();
    for (final entry in _herbicideMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return const _HerbicideInfo('Glyphosate 41% SL', '2.0–3.0 L/ha', 'Post-emergent', '0xFF558B2F');
  }

  @override
  Widget build(BuildContext context) {
    final weeds = result.detections.where((d) => !_isCrop(d.label)).toList();
    if (weeds.isEmpty) return const SizedBox.shrink();

    // Unique weed names
    final seen = <String>{};
    final uniqueWeeds = weeds.where((d) => seen.add(d.label.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.science_outlined, color: Color(0xFFE65100), size: 14),
              const SizedBox(width: 5),
              Text(AppLocalizations.of(context).herbicideRec, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE0B2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(AppLocalizations.of(context).weedCol, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5C5C5C)))),
                  Expanded(flex: 3, child: Text(AppLocalizations.of(context).herbicide, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5C5C5C)))),
                  Expanded(flex: 2, child: Text(AppLocalizations.of(context).dose, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5C5C5C)))),
                  Expanded(flex: 2, child: Text(AppLocalizations.of(context).type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5C5C5C)))),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFFFFE0B2)),
              ...uniqueWeeds.asMap().entries.map((e) {
                final i = e.key;
                final weed = e.value;
                final info = _getHerbicide(weed.label);
                final color = Color(int.parse(info.colorHex));
                final isLast = i == uniqueWeeds.length - 1;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 3, child: Row(children: [
                        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 3, right: 6),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        Expanded(child: Text(weed.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                      ])),
                      Expanded(flex: 3, child: Text(info.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
                      Expanded(flex: 2, child: Text(info.dose, style: const TextStyle(fontSize: 10, color: Color(0xFF5C5C5C)))),
                      Expanded(flex: 2, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(info.type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                      )),
                    ]),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF5E6D3)),
                ]);
              }),
              // Safety note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFFE65100)),
                  SizedBox(width: 6),
                  Expanded(child: Text(
                    'Always wear protective gear. Apply during calm weather. Follow label instructions and local regulations.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF795548), height: 1.4),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HerbicideInfo {
  final String name;
  final String dose;
  final String type;
  final String colorHex;
  const _HerbicideInfo(this.name, this.dose, this.type, this.colorHex);
}

// ─── Field Zones Screen ───────────────────────────────────────────────────────

class _FieldZonesScreen extends StatelessWidget {
  final WeedDetectionResult result;
  final String? scanId;
  final VoidCallback onBack;
  final VoidCallback onSaveScan;

  const _FieldZonesScreen({required this.result, this.scanId, required this.onBack, required this.onSaveScan});

  @override
  Widget build(BuildContext context) {
    final zones = result.zones.isNotEmpty ? result.zones : _mockZones;
    final priorityZone = result.priorityZone ?? zones
        .reduce((a, b) => a.weedCount >= b.weedCount ? a : b)
        .zoneLabel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            Text(AppLocalizations.of(context).appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
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
                  onPressed: onSaveScan,
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
      if (d.boundingBox == null) continue;
      final color = _labelColors[d.label] ?? const Color(0xFFE53935);
      final rect = Rect.fromLTWH(
        d.boundingBox!.x * size.width,
        d.boundingBox!.y * size.height,
        d.boundingBox!.width * size.width,
        d.boundingBox!.height * size.height,
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
