import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../core/l10n/app_localizations.dart';

final scanHistoryProvider = FutureProvider<List<ScanModel>>((ref) async {
  return ScanRepository(Supabase.instance.client).getAllScans();
});

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});
  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  String _search = '';
  SeverityLevel? _filterSeverity;

  @override
  void initState() {
    super.initState();
    // Always refresh when screen is opened so new scans appear immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(scanHistoryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scansAsync = ref.watch(scanHistoryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: const Color(0xFF2D6A4F),
        onRefresh: () async => ref.invalidate(scanHistoryProvider),
        child: scansAsync.when(
          loading: () => const _HistorySkeleton(),
          error: (_, __) => ErrorState(message: 'Unable to load scan history.', onRetry: () => ref.invalidate(scanHistoryProvider)),
          data: (scans) {
            // Apply search + filter
            var filtered = scans.where((s) {
              final matchSeverity = _filterSeverity == null || s.severity == _filterSeverity;
              final matchSearch = _search.isEmpty ||
                s.weedCount.toString().contains(_search) ||
                s.createdAt.toString().contains(_search);
              return matchSeverity && matchSearch;
            }).toList();

            if (scans.isEmpty) return _EmptyHistoryView();
            return Column(
              children: [
                _HistoryHeader(onCompare: () => context.push('/comparison')),
                // Search + filter bar
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCFDFCF)),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: l10n.scanHistory + '...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9E9E9E)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(label: l10n.low, color: const Color(0xFF388E3C),
                      selected: _filterSeverity == SeverityLevel.low,
                      onTap: () => setState(() => _filterSeverity = _filterSeverity == SeverityLevel.low ? null : SeverityLevel.low)),
                    const SizedBox(width: 4),
                    _FilterChip(label: l10n.moderate, color: const Color(0xFFF57F17),
                      selected: _filterSeverity == SeverityLevel.moderate,
                      onTap: () => setState(() => _filterSeverity = _filterSeverity == SeverityLevel.moderate ? null : SeverityLevel.moderate)),
                    const SizedBox(width: 4),
                    _FilterChip(label: l10n.high, color: const Color(0xFFC62828),
                      selected: _filterSeverity == SeverityLevel.high,
                      onTap: () => setState(() => _filterSeverity = _filterSeverity == SeverityLevel.high ? null : SeverityLevel.high)),
                  ]),
                ),
                Expanded(
                  child: filtered.isEmpty
                    ? Center(child: Text(l10n.noHistory, style: const TextStyle(color: Color(0xFF9E9E9E))))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ScanHistoryCard(scan: filtered[i]),
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : color)),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final VoidCallback onCompare;
  const _HistoryHeader({required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 0, 12),
            child: Text('Scan history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1B4332))),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.compare_arrows_outlined, color: Color(0xFF1B4332)), onPressed: onCompare),
        ],
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_outlined, color: Color(0xFF2D6A4F), size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('No scans recorded',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1B4332))),
                  const SizedBox(height: 10),
                  const Text(
                    'Your scan history will appear here after you scan a field.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B8F71), height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => context.push('/scanner'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Scan a field', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ScanHistoryCard extends StatelessWidget {
  final ScanModel scan;
  const _ScanHistoryCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show scan detail bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ScanDetailSheet(scan: scan),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F0E8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFE8F5E9),
                    child: scan.imageUrl != null && scan.imageUrl!.isNotEmpty
                        ? (scan.imageUrl!.startsWith('http')
                            ? Image.network(
                                scan.imageUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.photo_camera_rounded,
                                  color: Color(0xFF2D6A4F),
                                  size: 20,
                                ),
                              )
                            : Image.file(
                                File(scan.imageUrl!),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.photo_camera_rounded,
                                  color: Color(0xFF2D6A4F),
                                  size: 20,
                                ),
                              ))
                        : const Icon(
                            Icons.photo_camera_rounded,
                            color: Color(0xFF2D6A4F),
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatDateTime(scan.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B4332),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${scan.weedCount} weed${scan.weedCount == 1 ? '' : 's'} recorded',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B8F71),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SeverityChip(severity: scan.severity, small: true),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8F0E8)),
              ),
              child: Row(
                children: [
                  _Stat(
                    value: scan.weedCount.toString(),
                    label: AppLocalizations.of(context).weedsDetected,
                    color: const Color(0xFF2D6A4F),
                  ),
                  const Spacer(),
                  _Stat(
                    value: '${(scan.averageConfidence * 100).toStringAsFixed(0)}%',
                    label: AppLocalizations.of(context).confidence,
                    color: const Color(0xFF3A86C8),
                  ),
                  if (scan.priorityZone != null) ...[
                    const Spacer(),
                    _Stat(
                      value: scan.priorityZone!,
                      label: 'Priority',
                      color: const Color(0xFFF4A261),
                    ),
                  ],
                ],
              ),
            ),
            if (scan.isMockDetection) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Demo detection',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanDetailSheet extends StatelessWidget {
  final ScanModel scan;
  const _ScanDetailSheet({required this.scan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
            if (scan.imageUrl != null && scan.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(scan.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 80, color: const Color(0xFFE8F5E9),
                    child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF2D6A4F), size: 32))),
              ),
            const SizedBox(height: 16),
            Text(DateFormatter.formatDateTime(scan.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 12),
            Row(children: [
              _DetailStat(value: scan.weedCount.toString(), label: l10n.weedsDetected, color: const Color(0xFFC62828)),
              const SizedBox(width: 24),
              _DetailStat(value: '${(scan.averageConfidence * 100).toStringAsFixed(0)}%', label: l10n.confidence, color: const Color(0xFF3A86C8)),
              const SizedBox(width: 24),
              _DetailStat(value: scan.severity.name.toUpperCase(), label: l10n.severity, color: const Color(0xFF2D6A4F)),
            ]),
            if (scan.priorityZone != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 8),
                  Text('Priority: ${scan.priorityZone}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                ]),
              ),
            ],
          ])),
        ]),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _DetailStat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
    ]);
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(height: 88, decoration: BoxDecoration(color: const Color(0xFFEBF5EB), borderRadius: BorderRadius.circular(14))),
    );
  }
}
