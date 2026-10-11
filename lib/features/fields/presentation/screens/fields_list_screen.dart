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
                  if (fields.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FieldsEmptyState(
                        onAdd: () async {
                          await context.push('/fields/new');
                          ref.invalidate(fieldsProvider);
                        },
                      ),
                    )
                  else ...[
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _FieldsEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          children: [
            // Card matching the template perfectly
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Beautiful landscape field header
                  Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/fields_hero.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Floating circular leaf badge in center
                      Positioned(
                        bottom: -30,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Color(0xFF2D6A4F),
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  // "No fields yet" text
                  const Text(
                    'No fields yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Add your first field to start scanning for weeds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Primary green action button matching the template: (+) Add field ->
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF1B5E20).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Add field',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
