import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';

class ScanComparisonScreen extends ConsumerStatefulWidget {
  final String? previousScanId;
  final String? currentScanId;
  const ScanComparisonScreen({super.key, this.previousScanId, this.currentScanId});

  @override
  ConsumerState<ScanComparisonScreen> createState() => _ScanComparisonScreenState();
}

class _ScanComparisonScreenState extends ConsumerState<ScanComparisonScreen> {
  List<ScanModel> _scans = [];
  ScanModel? _previous;
  ScanModel? _current;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ScanRepository(Supabase.instance.client);
      _scans = await repo.getAllScans();
      if (_scans.length >= 2) {
        _current = widget.currentScanId != null
            ? _scans.firstWhere((s) => s.id == widget.currentScanId, orElse: () => _scans.first)
            : _scans.first;
        final currentIndex = _scans.indexOf(_current!);
        _previous = currentIndex < _scans.length - 1 ? _scans[currentIndex + 1] : null;
      }
    } catch (_) {
      _error = 'Unable to load scans for comparison.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan comparison')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _scans.length < 2
                  ? _NotEnoughScans()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ScanSelector(
                            label: 'Baseline scan',
                            scans: _scans,
                            selected: _previous,
                            onChanged: (s) => setState(() => _previous = s),
                          ),
                          const SizedBox(height: 12),
                          _ScanSelector(
                            label: 'Comparison scan',
                            scans: _scans,
                            selected: _current,
                            onChanged: (s) => setState(() => _current = s),
                          ),
                          const SizedBox(height: 20),
                          if (_previous != null && _current != null) _ComparisonResult(previous: _previous!, current: _current!),
                        ],
                      ),
                    ),
    );
  }
}

class _ScanSelector extends StatelessWidget {
  final String label;
  final List<ScanModel> scans;
  final ScanModel? selected;
  final ValueChanged<ScanModel?> onChanged;
  const _ScanSelector({required this.label, required this.scans, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ScanModel>(
      value: selected,
      decoration: InputDecoration(labelText: label),
      items: scans.map((s) => DropdownMenuItem(
        value: s,
        child: Text(DateFormatter.formatDateTime(s.createdAt), overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

class _ComparisonResult extends StatelessWidget {
  final ScanModel previous;
  final ScanModel current;
  const _ComparisonResult({required this.previous, required this.current});

  @override
  Widget build(BuildContext context) {
    final weedDelta = current.weedCount - previous.weedCount;
    final sign = weedDelta >= 0 ? '+' : '';
    final deltaColor = weedDelta > 0 ? AppColors.severityHigh : weedDelta < 0 ? AppColors.severityLow : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comparison result', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _CompareColumn(label: 'Baseline', scan: previous)),
                  Container(width: 1, height: 80, color: AppColors.border),
                  Expanded(child: _CompareColumn(label: 'Latest', scan: current)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weed count change', style: Theme.of(context).textTheme.bodyMedium),
                  Text('$sign$weedDelta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: deltaColor)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Severity change', style: Theme.of(context).textTheme.bodyMedium),
                  Row(
                    children: [
                      SeverityChip(severity: previous.severity, small: true),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textDisabled)),
                      SeverityChip(severity: current.severity, small: true),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Changes reflect the difference between two scan timestamps. Infestation trends should be interpreted alongside field conditions and applied treatments.',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareColumn extends StatelessWidget {
  final String label;
  final ScanModel scan;
  const _CompareColumn({required this.label, required this.scan});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(scan.weedCount.toString(), style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('weeds', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SeverityChip(severity: scan.severity, small: true),
      ],
    );
  }
}

class _NotEnoughScans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare_arrows_outlined, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text('Two scans needed', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Scan a field at least twice to compare results over time.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
