import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';
import '../../../../shared/widgets/empty_state.dart';
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
      appBar: AppBar(
        title: const Text('Scan history'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_outlined),
            tooltip: 'Compare scans',
            onPressed: () => context.push('/comparison'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(scanHistoryProvider),
        child: scansAsync.when(
          loading: () => const _HistorySkeleton(),
          error: (_, __) => ErrorState(
            message: 'Unable to load scan history.',
            onRetry: () => ref.invalidate(scanHistoryProvider),
          ),
          data: (scans) {
            if (scans.isEmpty) {
              return const EmptyState(
                icon: Icons.history_outlined,
                title: 'No scans recorded',
                subtitle: 'Scans you perform will appear here for review and comparison.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: scans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ScanHistoryCard(scan: scans[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  final ScanModel scan;
  const _ScanHistoryCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(DateFormatter.formatDateTime(scan.createdAt), style: Theme.of(context).textTheme.bodySmall),
              ),
              SeverityChip(severity: scan.severity, small: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(value: scan.weedCount.toString(), label: 'Weeds'),
              const SizedBox(width: 20),
              _Stat(value: '${(scan.averageConfidence * 100).toStringAsFixed(0)}%', label: 'Confidence'),
              if (scan.priorityZone != null) ...[
                const SizedBox(width: 20),
                _Stat(value: scan.priorityZone!, label: 'Priority zone'),
              ],
            ],
          ),
          if (scan.isMockDetection) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('Demo detection', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 88,
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
