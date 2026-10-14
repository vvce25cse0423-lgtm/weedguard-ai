import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/field_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../../data/fields_repository.dart';
import '../../../history/presentation/screens/scan_history_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../../shared/widgets/scan_thumbnail_image.dart';

final fieldDetailProvider = FutureProvider.family<FieldModel, String>((ref, id) async {
  return FieldsRepository(Supabase.instance.client).getField(id);
});

final fieldScansProvider = FutureProvider.family<List<ScanModel>, String>((ref, fieldId) async {
  return FieldsRepository(Supabase.instance.client).getScansForField(fieldId);
});

class FieldDetailScreen extends ConsumerWidget {
  final String fieldId;
  const FieldDetailScreen({super.key, required this.fieldId});

  Future<void> _editAreaInAcres(BuildContext context, WidgetRef ref, FieldModel field) async {
    final currentAcres = (field.areHectares != null) ? (field.areHectares! * 2.47105) : 3.70;
    final ctrl = TextEditingController(text: currentAcres.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.straighten_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Edit Field Area (Acres)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the field area in acres:', style: TextStyle(fontSize: 13, color: Color(0xFF5C5C5C))),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Area in Acres',
                  suffixText: 'Acres',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter area';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text('1 Acre ≈ 0.4047 Hectares', style: TextStyle(fontSize: 11, color: Color(0xFF8E8E8E))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            child: const Text('Save Acres'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final newAcres = double.tryParse(ctrl.text.trim());
      if (newAcres != null && newAcres > 0) {
        final newHectares = newAcres / 2.47105;
        final repo = FieldsRepository(Supabase.instance.client);
        await repo.updateField(field.copyWith(areHectares: newHectares));
        ref.invalidate(fieldDetailProvider(field.id));
        ref.invalidate(dashboardFieldsProvider);
      }
    }
  }

  Future<void> _editLocation(BuildContext context, WidgetRef ref, FieldModel field) async {
    final ctrl = TextEditingController(text: field.locationLabel ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Field Location & Reallocation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update farmland plot location:', style: TextStyle(fontSize: 13, color: Color(0xFF5C5C5C))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Location / Plot Name',
                hintText: 'e.g. North Plot - Block 1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final repo = FieldsRepository(Supabase.instance.client);
      await repo.updateField(field.copyWith(locationLabel: ctrl.text.trim()));
      ref.invalidate(fieldDetailProvider(field.id));
      ref.invalidate(dashboardFieldsProvider);
    }
  }

  void _showTotalPriorityZonesSheet(BuildContext context, FieldModel field, List<ScanModel> scans) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TotalPriorityZonesSheet(field: field, scans: scans),
    );
  }

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
        error: (e, _) => const Center(child: Text('Unable to load field details.')),
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
                _FieldInfoCard(
                  field: field,
                  scans: scansAsync.value ?? [],
                  onEditAcres: () => _editAreaInAcres(context, ref, field),
                  onEditLocation: () => _editLocation(context, ref, field),
                ),
                const SizedBox(height: 16),

                // Action Buttons: Scan this field & Total Priority Zones
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/scanner?fieldId=$fieldId'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Scan this field', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _showTotalPriorityZonesSheet(context, field, scansAsync.value ?? []),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                            side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                          label: Text(
                            'Total Priority Zones (${scansAsync.value?.length ?? 0})',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ScanHistoryCard(scan: s),
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
  final List<ScanModel> scans;
  final VoidCallback onEditAcres;
  final VoidCallback onEditLocation;

  const _FieldInfoCard({
    required this.field,
    required this.scans,
    required this.onEditAcres,
    required this.onEditLocation,
  });

  @override
  Widget build(BuildContext context) {
    final double hectares = field.areHectares ?? 1.5;
    final double acres = hectares * 2.47105;

    return Container(
      padding: const EdgeInsets.all(18),
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
          _InfoRow(icon: Icons.grass_rounded, label: 'Crop', value: field.cropType),
          const Divider(height: 20, color: Color(0xFFF0F4F0)),

          // Area with Editable Acres Button
          _InfoRow(
            icon: Icons.straighten_rounded,
            label: 'Area',
            value: '${acres.toStringAsFixed(2)} Acres (${hectares.toStringAsFixed(2)} ha)',
            trailing: InkWell(
              onTap: onEditAcres,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 13, color: Color(0xFF1B5E20)),
                    SizedBox(width: 4),
                    Text('Edit Acres', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF0F4F0)),

          // Location with Reallocation of Scanned Images
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: 'Location & Reallocation',
            value: field.locationLabel ?? 'Farmland Plot 1 (Active)',
            trailing: InkWell(
              onTap: onEditLocation,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_location_alt_rounded, size: 13, color: Color(0xFF1B5E20)),
                    SizedBox(width: 4),
                    Text('Reallocate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
                  ],
                ),
              ),
            ),
          ),

          // Reallocation of scanned images chips
          if (scans.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8F0E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scanned Image Reallocation Points:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A7A4A))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: scans.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final zoneLabel = s.priorityZone ?? 'Zone ${String.fromCharCode(65 + (i % 26))}';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_rounded, size: 12, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              '$zoneLabel (${s.weedCount} weeds)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B4332)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          if (field.plantingDate != null) ...[
            const Divider(height: 20, color: Color(0xFFF0F4F0)),
            _InfoRow(icon: Icons.calendar_today_rounded, label: 'Planted', value: DateFormatter.formatDate(field.plantingDate!)),
          ],
          if (field.notes != null && field.notes!.isNotEmpty) ...[
            const Divider(height: 20, color: Color(0xFFF0F4F0)),
            _InfoRow(icon: Icons.notes_rounded, label: 'Notes', value: field.notes!),
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
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B8F71),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Total Priority Zones Sheet ───────────────────────────────────────────────

class _TotalPriorityZonesSheet extends StatelessWidget {
  final FieldModel field;
  final List<ScanModel> scans;

  const _TotalPriorityZonesSheet({required this.field, required this.scans});

  Color _severityColor(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.low: return const Color(0xFF2E7D32);
      case SeverityLevel.moderate: return const Color(0xFFE65100);
      case SeverityLevel.high: return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWeeds = scans.fold<int>(0, (sum, s) => sum + s.weedCount);

    // Sort scans by highest weed count for priority weeds ranking
    final sortedByPriority = [...scans]..sort((a, b) => b.weedCount.compareTo(a.weedCount));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF1B5E20), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Priority Zones',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 2),
                        Text('${field.name} (${field.cropType}) • ${scans.length} Zones',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF5C5C5C), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8F0E8)),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                children: [
                  // Overview Stats Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(label: 'Total Zones', value: '${scans.length}'),
                        Container(width: 1, height: 36, color: const Color(0xFFA5D6A7)),
                        _StatBox(label: 'Total Weeds', value: '$totalWeeds'),
                        Container(width: 1, height: 36, color: const Color(0xFFA5D6A7)),
                        _StatBox(
                          label: 'Highest Alert',
                          value: scans.any((s) => s.severity == SeverityLevel.high)
                              ? 'High'
                              : scans.any((s) => s.severity == SeverityLevel.moderate)
                                  ? 'Moderate'
                                  : 'Low',
                          valueColor: scans.any((s) => s.severity == SeverityLevel.high)
                              ? const Color(0xFFC62828)
                              : const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── SKETCH OF TOTAL ZONES PRESENT IN CROP FIELD ────────────
                  Row(
                    children: [
                      const Icon(Icons.grid_on_rounded, size: 18, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 8),
                      const Text(
                        'Sketch of Total Zones in Farmland',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visual parcel map of all scanned images recorded for this field:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
                  ),
                  const SizedBox(height: 12),

                  if (scans.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8F0E8)),
                      ),
                      child: const Center(
                        child: Text(
                          'No scanned images yet. Scan farmland to map Zone A, Zone B, etc.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E8E)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    // Parcel Grid Layout Sketch
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: scans.length,
                      itemBuilder: (context, i) {
                        final s = scans[i];
                        final zoneLabel = s.priorityZone ?? 'Zone ${String.fromCharCode(65 + (i % 26))}';
                        final color = _severityColor(s.severity);

                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ScanDetailSheet(scan: s),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Scanned Image Thumbnail
                                ScanThumbnailImage(
                                  imageUrl: s.imageUrl,
                                  createdAt: s.createdAt,
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: BorderRadius.zero,
                                ),
                                // Gradient Overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.6),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                ),
                                // Top Zone Badge
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      zoneLabel,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                    ),
                                  ),
                                ),
                                // Bottom Priority & Weed Count
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${s.weedCount} weeds',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                      Text(
                                        s.severity.label + ' Priority',
                                        style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // ─── PRIORITY WEEDS BREAKDOWN ───────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.format_list_numbered_rounded, size: 18, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 8),
                      const Text(
                        'Priority Weeds Ranking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Order of priority for targeted herbicide intervention:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
                  ),
                  const SizedBox(height: 12),

                  if (scans.isEmpty)
                    const Text('No weed data recorded yet.')
                  else
                    ...sortedByPriority.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final s = e.value;
                      final originalIndex = scans.indexOf(s);
                      final zoneLabel = s.priorityZone ?? 'Zone ${String.fromCharCode(65 + (originalIndex >= 0 ? originalIndex : 0) % 26)}';
                      final color = _severityColor(s.severity);
                      final speciesText = s.weedNames.isNotEmpty ? s.weedNames.join(', ') : 'Mixed Weeds';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '$zoneLabel — ${s.weedCount} weeds',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${s.severity.label} Priority',
                                          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Species: $speciesText',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF5C5C5C), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ScanDetailSheet(scan: s),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1B5E20),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF1B4332))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4A7A4A), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _NoScansCard extends StatelessWidget {
  const _NoScansCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_camera_outlined, size: 28, color: Color(0xFF2D6A4F)),
          ),
          const SizedBox(height: 12),
          const Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the Scan button above to capture and analyse this field.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B8F71),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
