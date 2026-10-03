import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/field_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../../data/fields_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';

final fieldDetailProvider = FutureProvider.family<FieldModel, String>((ref, id) async {
  return FieldsRepository(Supabase.instance.client).getField(id);
});

final fieldScansProvider = FutureProvider.family<List<ScanModel>, String>((ref, fieldId) async {
  return FieldsRepository(Supabase.instance.client).getScansForField(fieldId);
});

class FieldDetailScreen extends ConsumerWidget {
  final String fieldId;
  const FieldDetailScreen({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldAsync = ref.watch(fieldDetailProvider(fieldId));
    final scansAsync = ref.watch(fieldScansProvider(fieldId));

    return Scaffold(
      appBar: AppBar(
        title: fieldAsync.maybeWhen(data: (f) => Text(f.name), orElse: () => const Text('Field')),
        actions: [
          fieldAsync.maybeWhen(
            data: (field) => PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await context.push('/fields/$fieldId/edit');
                  ref.invalidate(fieldDetailProvider(fieldId));
                } else if (value == 'delete') {
                  final confirm = await _confirmDelete(context);
                  if (confirm == true) {
                    await FieldsRepository(Supabase.instance.client).deleteField(fieldId);
                    if (context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit field')),
                PopupMenuItem(value: 'delete', child: Text('Delete field')),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: fieldAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load field details.')),
        data: (field) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(fieldDetailProvider(fieldId));
            ref.invalidate(fieldScansProvider(fieldId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldInfoCard(field: field),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/scanner?fieldId=$fieldId'),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Scan this field'),
                ),
                const SizedBox(height: 24),
                Text('Scan history', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                scansAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Unable to load scan history.'),
                  data: (scans) {
                    if (scans.isEmpty) {
                      return const _NoScansCard();
                    }
                    return Column(
                      children: scans
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ScanHistoryTile(scan: s),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete field?'),
        content: const Text('All scans associated with this field will also be deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FieldInfoCard extends StatelessWidget {
  final FieldModel field;
  const _FieldInfoCard({required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.grass_outlined, label: 'Crop', value: field.cropType),
          if (field.areHectares != null) ...[
            const Divider(height: 20),
            _InfoRow(icon: Icons.straighten_outlined, label: 'Area', value: '${field.areHectares!.toStringAsFixed(2)} hectares'),
          ],
          if (field.locationLabel != null) ...[
            const Divider(height: 20),
            _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: field.locationLabel!),
          ],
          if (field.plantingDate != null) ...[
            const Divider(height: 20),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Planted', value: DateFormatter.formatDate(field.plantingDate!)),
          ],
          if (field.notes != null && field.notes!.isNotEmpty) ...[
            const Divider(height: 20),
            _InfoRow(icon: Icons.notes_outlined, label: 'Notes', value: field.notes!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }
}

class _NoScansCard extends StatelessWidget {
  const _NoScansCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.photo_camera_outlined, size: 36, color: AppColors.textDisabled),
          const SizedBox(height: 10),
          Text('No scans yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Use the Scan button above to capture and analyse this field.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ScanHistoryTile extends StatelessWidget {
  final ScanModel scan;
  const _ScanHistoryTile({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormatter.formatDateTime(scan.createdAt), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('${scan.weedCount} weeds detected', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          SeverityChip(severity: scan.severity),
        ],
      ),
    );
  }
}
