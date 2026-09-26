import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/field_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../fields/data/fields_repository.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';
import '../../../../core/utils/date_formatter.dart';

final dashboardFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return FieldsRepository(Supabase.instance.client).getFields();
});

final dashboardScansProvider = FutureProvider<List<ScanModel>>((ref) async {
  return ScanRepository(Supabase.instance.client).getAllScans();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(dashboardFieldsProvider);
    final scansAsync = ref.watch(dashboardScansProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'Nitin';
    final firstName = name.split(' ').first;

    final fields = fieldsAsync.valueOrNull ?? [];
    final scans = scansAsync.valueOrNull ?? [];
    final highCount =
        scans.where((s) => s.severity == SeverityLevel.high).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroSection(greeting: '$_greeting, $firstName'),
                  const SizedBox(height: 16),
                  _StatsCards(
                    fieldsCount: fields.length,
                    scansCount: scans.length,
                    highCount: highCount,
                  ),
                  const SizedBox(height: 24),
                  _QuickActions(
                    onScan: () => context.push('/scanner'),
                    onAddField: () => context.push('/fields/new'),
                    onHistory: () => context.go('/history'),
                  ),
                  const SizedBox(height: 24),
                  _RecentScans(
                    scansAsync: scansAsync,
                    onViewAll: () => context.go('/history'),
                    onScan: () => context.push('/scanner'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _BottomNav(
            currentIndex: _navIndex,
            onTap: (i) {
              setState(() => _navIndex = i);
              switch (i) {
                case 1:
                  context.go('/fields');
                  break;
                case 2:
                  context.go('/history');
                  break;
                case 3:
                  context.go('/settings');
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO SECTION — matches image: real photo bg + overlays
// ─────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final String greeting;
  const _HeroSection({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      width: double.infinity,
      height: 270 + top,
      child: Stack(
        children: [
          // Real farm field photo background
          Positioned.fill(
            child: Image.asset(
              'assets/images/dashboard_hero.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark green gradient overlay (top) + sun glow (top right)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B4332).withOpacity(0.82),
                    const Color(0xFF2D6A4F).withOpacity(0.70),
                    const Color(0xFF40916C).withOpacity(0.50),
                    const Color(0xFF52B788).withOpacity(0.30),
                  ],
                ),
              ),
            ),
          ),
          // Sun glow top-right
          Positioned(
            right: -20,
            top: top + 10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFC300).withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Wave / curved bottom of hero
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _HeroWavePainter(),
              child: const SizedBox(height: 48),
            ),
          ),
          // Decorative eco leaves bottom-left
          Positioned(
            left: -8,
            bottom: 14,
            child: Transform.rotate(
              angle: 0.3,
              child: const Icon(Icons.eco_rounded,
                  size: 52, color: Color(0x3552B788)),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(Icons.eco_rounded,
                  size: 36, color: Color(0x2552B788)),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar: Logo | WeedGuard | profile icon ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App icon — green rounded square with two leaf icons
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4332),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF52B788), width: 1.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 6,
                            left: 7,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: const Icon(Icons.eco_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 7,
                            child: Transform.rotate(
                              angle: 0.3,
                              child: const Icon(Icons.eco_rounded,
                                  color: Color(0xFF95D5B2), size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Brand name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'Weed',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3),
                            ),
                            TextSpan(
                              text: 'Guard',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF95D5B2),
                                  letterSpacing: -0.3),
                            ),
                          ]),
                        ),
                        const Text(
                          'Healthier Crops • Higher Yields',
                          style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Profile icon circle
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white54, width: 1.5),
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // ── Greeting row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 5),
                              Text(
                                DateFormatter.formatDate(DateTime.now()),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Script italic text top-right
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Farming\nfor a better\ntomorrow',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xCCFFFFFF),
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F4F0)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.25, 0, size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.65, size.width, size.height * 0.2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
// STATS CARDS — 3 cards: Fields (green), Scans (blue), High severity (yellow)
// ─────────────────────────────────────────────
class _StatsCards extends StatelessWidget {
  final int fieldsCount, scansCount, highCount;
  const _StatsCards(
      {required this.fieldsCount,
      required this.scansCount,
      required this.highCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.grass_rounded,
              label: 'Fields',
              count: fieldsCount,
              iconBg: const Color(0xFFD8F3DC),
              iconColor: const Color(0xFF2D6A4F),
              waveColor: const Color(0xFFD8F3DC),
              arrowColor: const Color(0xFF2D6A4F),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scans',
              count: scansCount,
              iconBg: const Color(0xFFDBEAF7),
              iconColor: const Color(0xFF3A86C8),
              waveColor: const Color(0xFFDBEAF7),
              arrowColor: const Color(0xFF3A86C8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.shield_outlined,
              label: 'High severity',
              count: highCount,
              iconBg: const Color(0xFFFFF3CD),
              iconColor: const Color(0xFFF4A261),
              waveColor: const Color(0xFFFFF3CD),
              arrowColor: const Color(0xFF2D6A4F),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color iconBg, iconColor, waveColor, arrowColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.iconBg,
    required this.iconColor,
    required this.waveColor,
    required this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Wave at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: _CardWavePainter(color: waveColor),
                child: const SizedBox(height: 38),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon circle
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 19),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        count.toString(),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B4332),
                            height: 1),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: arrowColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF40624F),
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardWavePainter extends CustomPainter {
  final Color color;
  const _CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.05, size.width * 0.5, size.height * 0.48)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.90, size.width, size.height * 0.38)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onScan, onAddField, onHistory;
  const _QuickActions(
      {required this.onScan,
      required this.onAddField,
      required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF2D6A4F), size: 22),
              SizedBox(width: 6),
              Text(
                'Quick actions',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Scan field',
                    onTap: onScan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                    icon: Icons.add_rounded,
                    label: 'Add field',
                    onTap: onAddField),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: onHistory),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8F3DC), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Decorative eco leaves bottom-right
              Positioned(
                right: -6,
                bottom: -6,
                child: const Icon(Icons.eco_rounded,
                    size: 40, color: Color(0xFFD8F3DC)),
              ),
              Positioned(
                right: 8,
                bottom: 2,
                child: const Icon(Icons.eco_rounded,
                    size: 22, color: Color(0xFFD8F3DC)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dark green filled circle with white icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                          color: Color(0xFF2D6A4F), shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4332)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RECENT SCANS
// ─────────────────────────────────────────────
class _RecentScans extends StatelessWidget {
  final AsyncValue<List<ScanModel>> scansAsync;
  final VoidCallback onViewAll, onScan;
  const _RecentScans(
      {required this.scansAsync,
      required this.onViewAll,
      required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: Color(0xFF2D6A4F), size: 20),
              const SizedBox(width: 6),
              const Text(
                'Recent scans',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF2D6A4F), size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: scansAsync.when(
            loading: () => _ScansSkeleton(),
            error: (_, __) => _ErrorCard(),
            data: (scans) => scans.isEmpty
                ? _EmptyScansCard(onScan: onScan)
                : _ScansList(scans: scans.take(5).toList()),
          ),
        ),
      ],
    );
  }
}

// Empty state — matches image: plant photo left, text+button right
class _EmptyScansCard extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyScansCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background eco leaves decoration top-right
            Positioned(
              right: -10,
              bottom: -10,
              child: const Icon(Icons.eco_rounded,
                  size: 80, color: Color(0xFFD8F3DC)),
            ),
            Positioned(
              right: 28,
              bottom: 6,
              child: const Icon(Icons.eco_rounded,
                  size: 44, color: Color(0xFFD8F3DC)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: plant image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: SizedBox(
                    width: 115,
                    height: 190,
                    child: Image.asset(
                      'assets/images/login_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Right: content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Camera icon circle
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                              color: Color(0xFFD8F3DC), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Color(0xFF2D6A4F), size: 20),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No scans yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4332)),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Scan a field to see weed detection results here.',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6B8F71),
                              fontWeight: FontWeight.w400,
                              height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        // Scan now button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onScan,
                            icon: const Icon(Icons.camera_alt_rounded, size: 15),
                            label: const Text('Scan now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D6A4F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScansList extends StatelessWidget {
  final List<ScanModel> scans;
  const _ScansList({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: scans
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Color(0xFFD8F3DC),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: const Icon(Icons.photo_camera_outlined,
                            color: Color(0xFF2D6A4F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.weedCount} weeds detected',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B4332)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatDateTime(s.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B8F71)),
                            ),
                          ],
                        ),
                      ),
                      SeverityChip(severity: s.severity, small: true),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _ScansSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
          3,
          (_) => Container(
                height: 66,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF5EB),
                    borderRadius: BorderRadius.circular(14)),
              )),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: const Text('Unable to load recent scans.',
          style: TextStyle(color: Color(0xFFC62828), fontSize: 13)),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM NAV — Dashboard(active), Fields, History, Settings
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Stack(
          children: [
            // Decorative leaves
            Positioned(
              left: -8,
              bottom: -8,
              child: const Icon(Icons.eco_rounded,
                  size: 55, color: Color(0xFFD8F3DC)),
            ),
            Positioned(
              right: -8,
              bottom: -8,
              child: const Icon(Icons.eco_rounded,
                  size: 55, color: Color(0xFFD8F3DC)),
            ),
            Padding(
              padding: EdgeInsets.only(top: 6, bottom: bottom + 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.grass_rounded,
                    label: 'Fields',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFFD8F3DC),
                      borderRadius: BorderRadius.circular(14))
                  : null,
              child: Icon(icon,
                  color: isActive
                      ? const Color(0xFF2D6A4F)
                      : const Color(0xFF6B8F71),
                  size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFF6B8F71),
              ),
            ),
            // Active indicator line
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 22,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
