import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/field_model.dart';
import '../../data/fields_repository.dart';
import '../widgets/field_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';

final fieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  final repo = FieldsRepository(Supabase.instance.client);
  return repo.getFields();
});

class FieldsListScreen extends ConsumerWidget {
  const FieldsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add field',
            onPressed: () async {
              await context.push('/fields/new');
              ref.invalidate(fieldsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(fieldsProvider),
        child: fieldsAsync.when(
          loading: () => const _FieldsSkeleton(),
          error: (e, _) => ErrorState(
            message: 'Unable to load fields. Pull down to retry.',
            onRetry: () => ref.invalidate(fieldsProvider),
          ),
          data: (fields) {
            if (fields.isEmpty) {
              return EmptyState(
                icon: Icons.grid_view_outlined,
                title: 'No fields yet',
                subtitle: 'Add your first field to start scanning for weeds.',
                actionLabel: 'Add field',
                onAction: () async {
                  await context.push('/fields/new');
                  ref.invalidate(fieldsProvider);
                },
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: fields.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => FieldCard(
                field: fields[i],
                onTap: () async {
                  await context.push('/fields/${fields[i].id}');
                  ref.invalidate(fieldsProvider);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/fields/new');
          ref.invalidate(fieldsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add field'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _FieldsSkeleton extends StatelessWidget {
  const _FieldsSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
