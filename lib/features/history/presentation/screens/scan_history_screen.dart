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

final scanHistoryProvider = FutureProvider<List<ScanModel>>((ref) async {
  return ScanRepository(Supabase.instance.client).getAllScans();
});

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      // No AppBar — the template image has its own header built-in
      body: RefreshIndicator(
        color: const Color(0xFF2D6A4F),
        onRefresh: () async => ref.invalidate(scanHistoryProvider),
        child: scansAsync.when(
          loading: () => const _HistorySkeleton(),
          error: (_, __) => ErrorState(message: 'Unable to load scan history.', onRetry: () => ref.invalidate(scanHistoryProvider)),
          data: (scans) {
            if (scans.isEmpty) return _EmptyHistoryView();
            return Column(
              children: [
                _HistoryHeader(onCompare: () => context.push('/comparison')),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: scans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ScanHistoryCard(scan: scans[i]),
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

class _HistoryHeader extends StatelessWidget {
  final VoidCallback onCompare;
  const _HistoryHeader({required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
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
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/history_bg.png', fit: BoxFit.contain, alignment: Alignment.center),
            Container(color: Colors.white.withOpacity(0.08)),
          ]),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EFE8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF2D6A4F), size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(DateFormatter.formatDateTime(scan.createdAt),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B8F71), fontWeight: FontWeight.w500))),
          SeverityChip(severity: scan.severity, small: true),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _Stat(value: scan.weedCount.toString(), label: 'Weeds', color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 24),
          _Stat(value: '${(scan.averageConfidence * 100).toStringAsFixed(0)}%', label: 'Confidence', color: const Color(0xFF3A86C8)),
          if (scan.priorityZone != null) ...[
            const SizedBox(width: 24),
            _Stat(value: scan.priorityZone!, label: 'Priority zone', color: const Color(0xFFF4A261)),
          ],
        ]),
        if (scan.isMockDetection) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(5)),
            child: const Text('Demo detection', style: TextStyle(fontSize: 10, color: Color(0xFF2D6A4F)))),
        ],
      ]),
    );
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
