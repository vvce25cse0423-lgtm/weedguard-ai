import 'dart:convert';
import 'dart:io';
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
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/app_providers.dart';

final dashboardFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return FieldsRepository(Supabase.instance.client).getFields();
});

final dashboardScansProvider = FutureProvider<List<ScanModel>>((ref) async {
  return ScanRepository(Supabase.instance.client).getAllScans();
});


// ── Weather (OpenWeatherMap API) ──────────────────────────────────────────────
const _owmApiKey = '624d64f50bcf3cf596ccf7693dce142f';

final weatherProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final client = HttpClient();
    // Default to Bangalore; update with geolocator for device location
    const lat = 12.9716;
    const lon = 77.5946;
    final req = await client.getUrl(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_owmApiKey&units=metric'));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final main   = json['main']    as Map<String, dynamic>?;
    final wind   = json['wind']    as Map<String, dynamic>?;
    final weather = (json['weather'] as List?)?.first as Map<String, dynamic>?;
    final clouds = json['clouds']  as Map<String, dynamic>?;
    final sys    = json['sys']     as Map<String, dynamic>?;
    return {
      'temp':       main?['temp'],
      'feels_like': main?['feels_like'],
      'humidity':   main?['humidity'],
      'wind':       wind?['speed'],
      'desc':       weather?['description'],
      'icon':       weather?['icon'],
      'main':       weather?['main'],
      'clouds':     clouds?['all'],
      'city':       json['name'],
      'country':    sys?['country'],
    };
  } catch (_) { return null; }
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h = DateTime.now().hour;
    if (h < 12) return l10n.get('dashboard_greeting_morning');
    if (h < 17) return l10n.get('dashboard_greeting_afternoon');
    return l10n.get('dashboard_greeting_evening');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(greeting: '${_greeting(context)}, $firstName'),
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
            _TipOfTheDay(),
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
    );
  }
}

// ─────────────────────────────────────────────
// HERO SECTION
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/dashboard_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B4332).withOpacity(0.45),
                    const Color(0xFF2D6A4F).withOpacity(0.30),
                    const Color(0xFF40916C).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _HeroWavePainter(bgColor: Theme.of(context).scaffoldBackgroundColor),
              child: const SizedBox(height: 48),
            ),
          ),
          Positioned(
            left: -8,
            bottom: 14,
            child: Transform.rotate(
              angle: 0.3,
              child: Opacity(
                opacity: 0.22,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/app_icon.png', width: 52, height: 52, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.2,
              child: Opacity(
                opacity: 0.15,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/app_icon.png', width: 36, height: 36, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/app_icon.png', width: 46, height: 46, fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
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
                    Consumer(
                      builder: (context, ref, _) {
                        final weatherAsync = ref.watch(weatherProvider);
                        return weatherAsync.when(
                          loading: () => Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(color: Colors.white38, width: 1.5),
                            ),
                            child: const Icon(Icons.thermostat_outlined, color: Colors.white70, size: 18),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (weather) {
                            if (weather == null) return const SizedBox.shrink();
                            final temp = weather['temp'];
                            final tempStr = temp != null ? '${temp.round()}°' : '--°';
                            return Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(19),
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(color: Colors.white38, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.thermostat_outlined, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(tempStr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    )),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
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
  final Color _bgColor;
  const _HeroWavePainter({required Color bgColor}) : _bgColor = bgColor;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _bgColor
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
// STATS CARDS
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
              label: AppLocalizations.of(context).navFields,
              count: fieldsCount,
              iconBg: const Color(0xFFD8F3DC),
              iconColor: const Color(0xFF2D6A4F),
              waveColor: const Color(0xFFD8F3DC),
              arrowColor: const Color(0xFF2D6A4F),
              customIconAsset: 'assets/icons/fields_icon.png',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.qr_code_scanner_rounded,
              label: AppLocalizations.of(context).totalScans,
              count: scansCount,
              iconBg: const Color(0xFFDBEAF7),
              iconColor: const Color(0xFF3A86C8),
              waveColor: const Color(0xFFDBEAF7),
              arrowColor: const Color(0xFF3A86C8),
              customIconAsset: 'assets/icons/scans_icon.png',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.shield_outlined,
              label: AppLocalizations.of(context).get('severity'),
              count: highCount,
              iconBg: const Color(0xFFFFF3CD),
              iconColor: const Color(0xFFF4A261),
              waveColor: const Color(0xFFFFF3CD),
              arrowColor: const Color(0xFF2D6A4F),
              customIconAsset: 'assets/icons/severity_icon.png',
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
  final String? customIconAsset;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.iconBg,
    required this.iconColor,
    required this.waveColor,
    required this.arrowColor,
    this.customIconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: customIconAsset != null
                        ? ClipOval(
                            child: Image.asset(
                              customIconAsset!,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(icon, color: iconColor, size: 19),
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
// QUICK ACTIONS — images fill full card width
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF2D6A4F), size: 22),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).get('scan_field'),
                style: const TextStyle(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Each card gets equal width; gaps: 2 × 10px
              final cardWidth = (constraints.maxWidth - 20) / 3;
              return Row(
                children: [
                  _ActionCard(
                    width: cardWidth,
                    icon: Icons.camera_alt_rounded,
                    label: AppLocalizations.of(context).scanField,
                    customAsset: 'assets/images/quick_scan_field.png',
                    onTap: onScan,
                  ),
                  const SizedBox(width: 10),
                  _ActionCard(
                    width: cardWidth,
                    icon: Icons.add_rounded,
                    label: AppLocalizations.of(context).addField,
                    customAsset: 'assets/images/quick_add_field.png',
                    onTap: onAddField,
                  ),
                  const SizedBox(width: 10),
                  _ActionCard(
                    width: cardWidth,
                    icon: Icons.history_rounded,
                    label: AppLocalizations.of(context).navHistory,
                    customAsset: 'assets/images/quick_history.png',
                    onTap: onHistory,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? customAsset;

  const _ActionCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
    this.customAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (customAsset != null) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 305 / 223,
              child: Image.asset(
                customAsset!,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 104,
        child: Container(
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
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Opacity(
                    opacity: 0.18,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/images/app_icon.png', width: 40, height: 40, fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 2,
                  child: Opacity(
                    opacity: 0.12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/images/app_icon.png', width: 22, height: 22, fit: BoxFit.cover),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
              Text(
                AppLocalizations.of(context).recentScans,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).viewAll,
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

class _EmptyScansCard extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyScansCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onScan,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/no_scans_placeholder.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
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
                    color: Theme.of(context).cardColor,
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
                              '${s.weedCount} ${AppLocalizations.of(context).weedsDetected}',
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



// ─────────────────────────────────────────────
// WEATHER CARD
// ─────────────────────────────────────────────
class _WeatherCard extends ConsumerWidget {
  static IconData _icon(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'clear':        return Icons.wb_sunny_rounded;
      case 'clouds':       return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':      return Icons.grain_rounded;
      case 'thunderstorm': return Icons.thunderstorm_rounded;
      case 'snow':         return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
      case 'haze':         return Icons.blur_on_rounded;
      default:             return Icons.wb_cloudy_rounded;
    }
  }

  static Color _iconColor(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'clear':        return const Color(0xFFFFA000);
      case 'clouds':       return const Color(0xFF78909C);
      case 'rain':
      case 'drizzle':      return const Color(0xFF1565C0);
      case 'thunderstorm': return const Color(0xFF4527A0);
      case 'snow':         return const Color(0xFF0288D1);
      default:             return const Color(0xFF546E7A);
    }
  }

  static List<Color> _gradientColors(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'clear':        return [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)];
      case 'rain':
      case 'drizzle':      return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
      case 'thunderstorm': return [const Color(0xFFEDE7F6), const Color(0xFFD1C4E9)];
      case 'snow':         return [const Color(0xFFE1F5FE), const Color(0xFFB3E5FC)];
      default:             return [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    return weatherAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1565C0)),
          )),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (w) {
        if (w == null) return const SizedBox.shrink();
        final temp      = (w['temp'] as num?)?.toDouble();
        final feelsLike = (w['feels_like'] as num?)?.toDouble();
        final humidity  = w['humidity'];
        final windSpd   = (w['wind'] as num?)?.toDouble();
        final desc      = w['desc'] as String? ?? '';
        final mainStr   = w['main'] as String?;
        final city      = w['city'] as String? ?? '';
        final country   = w['country'] as String? ?? '';
        final gradients = _gradientColors(mainStr);
        final iconColor = _iconColor(mainStr);
        final iconData  = _icon(mainStr);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradients,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Big weather icon
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 34),
                  ),
                  const SizedBox(width: 14),
                  // Temp + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              temp != null ? '${temp.toStringAsFixed(1)}°C' : '--°C',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: iconColor, height: 1),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                desc.isNotEmpty ? _capitalize(desc) : (mainStr ?? ''),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: iconColor.withOpacity(0.8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          _WeatherStat(icon: Icons.location_on_outlined, label: '$city, $country', color: iconColor),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          _WeatherStat(icon: Icons.thermostat_outlined, label: 'Feels ${feelsLike?.toStringAsFixed(0) ?? '--'}°C', color: iconColor),
                          const SizedBox(width: 12),
                          _WeatherStat(icon: Icons.water_drop_outlined, label: '${humidity ?? '--'}%', color: iconColor),
                          const SizedBox(width: 12),
                          _WeatherStat(icon: Icons.air_outlined, label: '${windSpd?.toStringAsFixed(1) ?? '--'} m/s', color: iconColor),
                        ]),
                      ],
                    ),
                  ),
                  // Live badge
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: iconColor)),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.cloud_sync_outlined, size: 16, color: iconColor.withOpacity(0.6)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _WeatherStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color.withOpacity(0.7)),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─────────────────────────────────────────────
// TIP OF THE DAY
// ─────────────────────────────────────────────
class _TipOfTheDay extends StatelessWidget {
  static const _tips = [
    'Apply herbicides early morning or late evening for best results.',
    'Rotate herbicides annually to prevent weed resistance.',
    'Scout fields weekly during peak weed germination season.',
    'Use GPS mapping to track weed hotspots across seasons.',
    'Maintain sharp spray nozzles for uniform herbicide coverage.',
    'Integrate cover crops to naturally suppress weed growth.',
    'Keep field edges clear — they are primary weed seed sources.',
    'Post-harvest tillage can reduce weed seed bank significantly.',
  ];

  String get _todaysTip {
    final idx = DateTime.now().day % _tips.length;
    return _tips[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Farming Tip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(_todaysTip, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    color: Theme.of(context).cardColor,
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
