import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/field_model.dart';
import '../../data/fields_repository.dart';
import '../widgets/field_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../core/l10n/app_localizations.dart';

final fieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  final repo = FieldsRepository(Supabase.instance.client);
  return repo.getFields();
});

class FieldsListScreen extends ConsumerStatefulWidget {
  const FieldsListScreen({super.key});

  @override
  ConsumerState<FieldsListScreen> createState() => _FieldsListScreenState();
}

class _FieldsListScreenState extends ConsumerState<FieldsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(fieldsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: fieldsAsync.when(
          loading: () => const _FieldsSkeleton(),
          error: (e, _) => ErrorState(
            message: 'Unable to load fields. Pull down to retry.',
            onRetry: () => ref.invalidate(fieldsProvider),
          ),
          data: (fields) {
            if (fields.isEmpty) {
              return _FieldsTemplateEmptyScreen(
                onAdd: () async {
                  await context.push('/fields/new');
                  ref.invalidate(fieldsProvider);
                },
                onProfile: () => context.push('/profile'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(fieldsProvider),
              child: CustomScrollView(
                slivers: [
                  // ── App header (logo + profile) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: 'Weed ',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Guard AI',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ]),
                              ),
                              Text(
                                AppLocalizations.of(context).tagline,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE8F5E9),
                                border: Border.all(
                                    color: const Color(0xFFC8E6C9), width: 1),
                              ),
                              child: Icon(Icons.person_outline,
                                  size: 18, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Page title row ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).myFields,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await context.push('/fields/new');
                              ref.invalidate(fieldsProvider);
                            },
                            child: Icon(Icons.add,
                                size: 30, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FieldCard(
                              field: fields[i],
                              onTap: () async {
                                await context.push('/fields/${fields[i].id}');
                                ref.invalidate(fieldsProvider);
                              },
                            ),
                          ),
                          childCount: fields.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _AddFieldButton(onTap: () async {
                          await context.push('/fields/new');
                          ref.invalidate(fieldsProvider);
                        }),
                      ),
                    ),
                  ],
                ),
              );
          },
        ),
      ),
    );
  }
}

class _FieldsTemplateEmptyScreen extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onProfile;
  const _FieldsTemplateEmptyScreen({required this.onAdd, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  // Template image perfectly scaled to width with natural aspect ratio
                  Image.asset(
                    'assets/images/fields_template.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),

                  // Top right Profile avatar tap zone
                  Positioned(
                    top: 14,
                    right: 18,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onProfile,
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Header '+' Add field icon tap zone
                  Positioned(
                    top: 86,
                    right: 18,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onAdd,
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // "Add field" bottom pill button tap zone
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    height: 72,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onAdd,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFieldButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add field',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
          ],
        ),
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
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
