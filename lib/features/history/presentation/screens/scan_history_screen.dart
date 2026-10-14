import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/scan_thumbnail_image.dart';
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
            // Deduplicate scans by ID and timestamp/image
            final uniqueScansMap = <String, ScanModel>{};
            for (final s in scans) {
              final key = s.id.isNotEmpty ? s.id : '${s.createdAt.millisecondsSinceEpoch}_${s.imageUrl ?? ""}';
              if (!uniqueScansMap.containsKey(key)) {
                uniqueScansMap[key] = s;
              }
            }
            final uniqueScans = uniqueScansMap.values.toList();

            // Apply search + filter
            var filtered = uniqueScans.where((s) {
              final matchSeverity = _filterSeverity == null || s.severity == _filterSeverity;
              final matchSearch = _search.isEmpty ||
                s.weedCount.toString().contains(_search) ||
                s.createdAt.toString().contains(_search);
              return matchSeverity && matchSearch;
            }).toList();

            if (uniqueScans.isEmpty) return _EmptyHistoryView();
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
                        itemBuilder: (_, i) => ScanHistoryCard(scan: filtered[i]),
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

class ScanHistoryCard extends StatelessWidget {
  final ScanModel scan;
  const ScanHistoryCard({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        // Show scan detail bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ScanDetailSheet(scan: scan),
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
                ScanThumbnailImage(
                  imageUrl: scan.imageUrl,
                  createdAt: scan.createdAt,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(10),
                  defaultIcon: Icons.photo_camera_rounded,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.spa_rounded, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            (scan.cropName != null && scan.cropName!.isNotEmpty)
                                ? l10n.translateCrop(scan.cropName)
                                : (scan.zones.isNotEmpty ? l10n.translateCrop('Paddy / Crop') : l10n.translateCrop('Field Crop')),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grass_rounded, size: 14, color: Color(0xFFC62828)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            scan.weedNames.isNotEmpty
                                ? scan.weedNames.map((w) => l10n.translateWeed(w)).join(', ')
                                : (scan.weedCount > 0 ? l10n.get('weed_name') : l10n.get('no_weeds_clean')),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB71C1C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                  if (scan.cropName != null && scan.cropName!.isNotEmpty) ...[
                    const Spacer(),
                    _Stat(
                      value: l10n.translateCrop(scan.cropName).split('(').first.trim(),
                      label: l10n.get('crop_name'),
                      color: const Color(0xFF2E7D32),
                    ),
                  ] else if (scan.priorityZone != null) ...[
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

class _HerbicideDetailInfo {
  final String name;
  final String dose;
  final String type;
  const _HerbicideDetailInfo({
    required this.name,
    required this.dose,
    required this.type,
  });
}

_HerbicideDetailInfo _lookupHerbicide(List<String> weedNames, String? cropName) {
  final text = weedNames.join(' ').toLowerCase();

  if (text.contains('amaranthus') || text.contains('pigweed')) {
    return const _HerbicideDetailInfo(
      name: 'Atrazine 50% WP',
      dose: '2.0 kg/ha',
      type: 'Pre & post-emergent selective',
    );
  }
  if (text.contains('cyperus') ||
      text.contains('nutgrass') ||
      text.contains('sedge') ||
      text.contains('motha')) {
    return const _HerbicideDetailInfo(
      name: 'Halosulfuron-methyl 75% WG (Sempra)',
      dose: '67 g/ha',
      type: 'Selective post-emergent',
    );
  }
  if (text.contains('digitaria') || text.contains('crabgrass')) {
    return const _HerbicideDetailInfo(
      name: 'Quizalofop-ethyl 5% EC (Targa Super)',
      dose: '1.0 L/ha',
      type: 'Selective post-emergent grass herbicide',
    );
  }
  if (text.contains('convolvulus') || text.contains('bindweed')) {
    return const _HerbicideDetailInfo(
      name: '2,4-D Amine Salt 58% SL',
      dose: '1.5 L/ha',
      type: 'Selective post-emergent broadleaf herbicide',
    );
  }
  if (text.contains('echinochloa') || text.contains('barnyard')) {
    return const _HerbicideDetailInfo(
      name: 'Bispyribac-sodium 10% SC (Nominee Gold)',
      dose: '200 ml/ha',
      type: 'Selective post-emergent (Paddy/Rice)',
    );
  }
  if (text.contains('parthenium') || text.contains('congress')) {
    return const _HerbicideDetailInfo(
      name: 'Metribuzin 70% WP (Sencor)',
      dose: '500 g/ha',
      type: 'Pre & post-emergent systemic',
    );
  }
  if (text.contains('chenopodium') ||
      text.contains('bathua') ||
      text.contains('lambsquarters')) {
    return const _HerbicideDetailInfo(
      name: 'Pendimethalin 30% EC (Stomp Extra)',
      dose: '1.0–1.2 L/ha',
      type: 'Pre-emergent residual herbicide',
    );
  }
  if (text.contains('oxalis') || text.contains('woodsorrel')) {
    return const _HerbicideDetailInfo(
      name: 'Fluroxypyr 20% EC',
      dose: '1.0 L/ha',
      type: 'Post-emergent broadleaf',
    );
  }
  if (text.contains('portulaca') || text.contains('purslane')) {
    return const _HerbicideDetailInfo(
      name: 'Pendimethalin 30% EC / Oxyfluorfen',
      dose: '2.0 L/ha',
      type: 'Pre-emergent selective',
    );
  }
  if (text.contains('eleusine') || text.contains('goosegrass')) {
    return const _HerbicideDetailInfo(
      name: 'Fenoxaprop-p-ethyl 9.3% EC (Whip Super)',
      dose: '625 ml/ha',
      type: 'Selective post-emergent',
    );
  }
  if (text.contains('lantana')) {
    return const _HerbicideDetailInfo(
      name: 'Glyphosate 41% SL / Triclopyr',
      dose: '3.0 L/ha',
      type: 'Non-selective systemic herbicide',
    );
  }

  final cropLower = (cropName ?? '').toLowerCase();
  if (cropLower.contains('paddy') || cropLower.contains('rice')) {
    return const _HerbicideDetailInfo(
      name: 'Pretilachlor 50% EC / Bispyribac-sodium',
      dose: '1.0 L/ha',
      type: 'Selective Paddy herbicide',
    );
  }

  return const _HerbicideDetailInfo(
    name: '2,4-D Ethyl Ester 38% EC / Pendimethalin',
    dose: '1.2 L/ha',
    type: 'Broad-spectrum field herbicide',
  );
}

class ScanDetailSheet extends StatelessWidget {
  final ScanModel scan;
  const ScanDetailSheet({super.key, required this.scan});

  static Future<void> _launchExternalUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open store link.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static void _showStoreOptions(BuildContext context, String herbicideName) {
    final cleanQuery = RegExp(r'\(([^)]+)\)').firstMatch(herbicideName)?.group(1) ??
        herbicideName.replaceAll('/', ' ').replaceAll('  ', ' ').trim();
    final query = '$cleanQuery herbicide';

    final amazonUrl = 'https://www.amazon.in/s?k=${Uri.encodeComponent(query)}';
    final flipkartUrl = 'https://www.flipkart.com/search?q=${Uri.encodeComponent(query)}';
    final bigHaatUrl = herbicideName.toLowerCase().contains('glyphosate')
        ? 'https://www.bighaat.com/collections/glyphosate-herbicides'
        : (herbicideName.toLowerCase().contains('selective')
            ? 'https://www.bighaat.com/collections/selective-herbicides'
            : 'https://www.bighaat.com/collections/herbicides');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2D6A4F), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buy $herbicideName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your preferred marketplace to order:',
                style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
              const SizedBox(height: 16),
              _DetailStoreTile(
                title: 'Amazon India',
                subtitle: 'Fast delivery & verified sellers',
                imageAsset: 'assets/icons/amazon_icon.png',
                icon: Icons.storefront_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _launchExternalUrl(context, amazonUrl);
                },
              ),
              const SizedBox(height: 10),
              _DetailStoreTile(
                title: 'Flipkart',
                subtitle: 'Agri store & bulk farm supplies',
                imageAsset: 'assets/icons/flipkart_icon.png',
                icon: Icons.shopping_cart_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _launchExternalUrl(context, flipkartUrl);
                },
              ),
              const SizedBox(height: 10),
              _DetailStoreTile(
                title: 'BigHaat Agri Store',
                subtitle: "India's largest certified agri-input platform",
                imageAsset: 'assets/icons/bighaat_icon.png',
                icon: Icons.eco_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _launchExternalUrl(context, bigHaatUrl);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final herbicide = _lookupHerbicide(scan.weedNames, scan.cropName);

    // Infestation metrics
    final double rawScore = scan.infestationScore ??
        (scan.severity == SeverityLevel.high
            ? 0.78
            : scan.severity == SeverityLevel.moderate
                ? 0.44
                : 0.16);
    final int infestationPercent = (rawScore * 100).round().clamp(1, 100);

    final Color severityColor = scan.severity == SeverityLevel.high
        ? const Color(0xFFC62828)
        : (scan.severity == SeverityLevel.moderate
            ? const Color(0xFFE65100)
            : const Color(0xFF2E7D32));

    final Color severityBg = scan.severity == SeverityLevel.high
        ? const Color(0xFFFFEBEE)
        : (scan.severity == SeverityLevel.moderate
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9));

    final String cropDisplayName = (scan.cropName != null && scan.cropName!.isNotEmpty)
        ? scan.cropName!
        : 'Agricultural Field Crop';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, size: 18, color: Color(0xFF2D6A4F)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Scan Agronomy Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF757575)),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                children: [
                  // ─── 1. SCANNED IMAGE ─────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ScanThumbnailImage(
                            imageUrl: scan.imageUrl,
                            createdAt: scan.createdAt,
                            height: 220,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(16),
                            defaultIcon: Icons.photo_library_outlined,
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.68),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                                  const SizedBox(width: 5),
                                  Text(
                                    DateFormatter.formatDateTime(scan.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (scan.isMockDetection)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D6A4F).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Demo scan',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 2. INFESTATION LEVEL CARD ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: severityBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: severityColor.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 20, color: severityColor),
                            const SizedBox(width: 8),
                            Text(
                              l10n.get('infestation_level'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${scan.severity.name.toUpperCase()} ($infestationPercent%)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (infestationPercent / 100.0).clamp(0.05, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.65),
                            valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailStat(
                                value: scan.weedCount.toString(),
                                label: l10n.weedsDetected,
                                color: severityColor,
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.grey[300]),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: _DetailStat(
                                  value: '${(scan.averageConfidence * 100).toStringAsFixed(0)}%',
                                  label: l10n.confidence,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.grey[300]),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: _DetailStat(
                                  value: scan.severity.label,
                                  label: l10n.severity,
                                  color: severityColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 3. CROP NAME CARD ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.get('crop_name'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.translateCrop(cropDisplayName),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: Text(
                            l10n.get('crop_field_protected'),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 4. WEED NAME CARD ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.grass_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.get('weed_names_detected'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${scan.weedCount} ${l10n.weedsDetected}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (scan.weedNames.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: scan.weedNames.map((w) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEF9A9A)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.grass_rounded, size: 14, color: Color(0xFFC62828)),
                                    const SizedBox(width: 5),
                                    Text(
                                      l10n.translateWeed(w),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        else if (scan.weedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF9A9A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.grass_rounded, size: 14, color: Color(0xFFC62828)),
                                const SizedBox(width: 6),
                                Text(
                                  '${l10n.weedsDetected} (${scan.weedCount})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB71C1C),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFC8E6C9)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.get('no_weeds_clean'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 5. HERBICIDES NAME CARD ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7FD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.science_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.get('herbicides_name'),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                  Text(
                                    l10n.herbicideRec,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3F2FD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                herbicide.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.water_drop_outlined, size: 13, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${l10n.dose}: ${herbicide.dose}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      herbicide.type,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF616161),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D6A4F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                            label: Text(
                              l10n.get('buy_herbicide_online'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            onPressed: () => _showStoreOptions(context, herbicide.name),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (scan.priorityZone != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFE65100), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.get('priority_treatment_zone')}: ${scan.priorityZone}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStoreTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final IconData icon;
  final VoidCallback onTap;

  const _DetailStoreTile({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                imageAsset,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF2D6A4F),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF9E9E9E)),
          ],
        ),
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
