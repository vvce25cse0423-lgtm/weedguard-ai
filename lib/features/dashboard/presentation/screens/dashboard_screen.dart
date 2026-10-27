import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/field_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../fields/data/fields_repository.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../scanner/presentation/widgets/severity_chip.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../spray_window/presentation/widgets/spray_window_dialog.dart';
import '../../../history/presentation/screens/scan_history_screen.dart';
import '../../../../shared/widgets/scan_thumbnail_image.dart';

final dashboardFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return FieldsRepository(Supabase.instance.client).getFields();
});

final dashboardScansProvider = FutureProvider<List<ScanModel>>((ref) async {
  return ScanRepository(Supabase.instance.client).getAllScans();
});


// ── Weather (OpenWeatherMap API) ──────────────────────────────────────────────
const _owmApiKey = AppConstants.openWeatherApiKey;

String _cleanWeatherPlaceName(String raw) {
  var name = raw.trim();
  name = name
      .replaceAll('ī', 'i')
      .replaceAll('Ĩ', 'I')
      .replaceAll('ā', 'a')
      .replaceAll('Ā', 'A')
      .replaceAll('ū', 'u')
      .replaceAll('Ū', 'U');

  name = name
      .replaceAll(RegExp(r'\s+taluk\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+district\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+hobli\b', caseSensitive: false), '')
      .trim();

  return name.isNotEmpty ? name : raw;
}

final weatherProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    double? lat;
    double? lon;

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        try {
          final lastPos = await Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            lat = lastPos.latitude;
            lon = lastPos.longitude;
          }
        } catch (_) {}

        if (lat == null || lon == null) {
          try {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 4),
            );
            lat = pos.latitude;
            lon = pos.longitude;
          } catch (_) {}
        }
      }
    } catch (_) {
      // GPS unavailable or timed out
    }

    final effectiveLat = lat ?? 12.9716;
    final effectiveLon = lon ?? 77.5946;

    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$effectiveLat&lon=$effectiveLon&appid=$_owmApiKey&units=metric'));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    
    // Reverse geocode to get natural place name
    String? resolvedCity;
    if (lat != null && lon != null) {
      try {
        final geoReq = await client.getUrl(Uri.parse(
          'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=5&appid=$_owmApiKey'));
        final geoRes = await geoReq.close();
        final geoBody = await geoRes.transform(utf8.decoder).join();
        final geoList = jsonDecode(geoBody) as List?;
        if (geoList != null && geoList.isNotEmpty) {
          final first = geoList.first as Map<String, dynamic>?;
          final placeName = first?['name'] as String?;
          if (placeName != null && placeName.trim().isNotEmpty) {
            resolvedCity = _cleanWeatherPlaceName(placeName);
          }
        }
      } catch (_) {}
    }
    client.close();

    final json = jsonDecode(body) as Map<String, dynamic>;
    final main   = json['main']    as Map<String, dynamic>?;
    final wind   = json['wind']    as Map<String, dynamic>?;
    final weather = (json['weather'] as List?)?.first as Map<String, dynamic>?;
    final clouds = json['clouds']  as Map<String, dynamic>?;
    final sys    = json['sys']     as Map<String, dynamic>?;
    final cityName = resolvedCity ?? _cleanWeatherPlaceName(json['name'] as String? ?? 'Bengaluru');

    return {
      'temp':       main?['temp'],
      'feels_like': main?['feels_like'],
      'humidity':   main?['humidity'],
      'pressure':   main?['pressure'],
      'wind':       wind?['speed'],
      'wind_speed': wind?['speed'],
      'wind_deg':   wind?['deg'],
      'desc':       weather?['description'],
      'icon':       weather?['icon'],
      'main':       weather?['main'],
      'clouds':     clouds?['all'],
      'city':       cityName,
      'country':    sys?['country'],
      'lat':        effectiveLat,
      'lon':        effectiveLon,
    };
  } catch (_) { return null; }
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();

    ref.invalidate(dashboardScansProvider);
    ref.invalidate(dashboardFieldsProvider);
    ref.invalidate(weatherProvider);
    ref.invalidate(userAvatarProvider);

    try {
      await Future.wait([
        ref.refresh(dashboardScansProvider.future),
        ref.refresh(dashboardFieldsProvider.future),
        ref.refresh(weatherProvider.future),
      ]);
    } catch (_) {}

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.invalidate(dashboardScansProvider);
      ref.invalidate(dashboardFieldsProvider);

      // Delay location permission prompt by 4 seconds for new users only
      Future.delayed(const Duration(seconds: 4), () async {
        if (!mounted) return;
        try {
          final prefs = await SharedPreferences.getInstance();
          final hasPrompted = prefs.getBool('has_prompted_location_permission') ?? false;
          final perm = await Geolocator.checkPermission();
          if (!hasPrompted && perm == LocationPermission.denied) {
            await prefs.setBool('has_prompted_location_permission', true);
            await Geolocator.requestPermission();
            if (mounted) {
              ref.invalidate(weatherProvider);
            }
          } else if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
            await prefs.setBool('has_prompted_location_permission', true);
          }
        } catch (_) {}
      });
    });
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
    final highCount = scans.where((s) =>
        s.severity == SeverityLevel.high ||
        s.severity == SeverityLevel.moderate ||
        s.weedCount > 0).length;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: Stack(
        children: [
          Positioned(
            top: 270 + topPadding - 48,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          RefreshIndicator(
            color: const Color(0xFF2D6A4F),
            backgroundColor: Colors.white,
            edgeOffset: topPadding,
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroSection(
                    greeting: '${_greeting(context)}, $firstName',
                  ),
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 20),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final String greeting;

  const _HeroSection({
    required this.greeting,
  });

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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: const TextSpan(children: [
                                TextSpan(
                                  text: 'Weed',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3),
                                ),
                                TextSpan(
                                  text: 'Guard',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF95D5B2),
                                      letterSpacing: -0.3),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final weatherAsync = ref.watch(weatherProvider);
                            final cachedData = weatherAsync.valueOrNull;
                            return GestureDetector(
                              onTap: () => context.push('/weather', extra: cachedData),
                              child: weatherAsync.when(
                                loading: () => Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.18),
                                    border: Border.all(color: Colors.white38, width: 1.5),
                                  ),
                                  child: const Icon(Icons.thermostat_outlined, color: Colors.white70, size: 16),
                                ),
                                error: (_, __) => Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.18),
                                    border: Border.all(color: Colors.white38, width: 1.5),
                                  ),
                                  child: const Icon(Icons.thermostat_outlined, color: Colors.white, size: 16),
                                ),
                                data: (weather) {
                                  final temp = weather?['temp'];
                                  final tempStr = temp != null ? '${temp.round()}°' : '28°';
                                  final main = weather?['main'] as String?;
                                  final emoji = _WeatherCard.weatherEmoji(main);
                                  return Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(17),
                                      color: Colors.white.withOpacity(0.18),
                                      border: Border.all(color: Colors.white54, width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(width: 4),
                                        Text(
                                          tempStr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => SprayWindowDialog.show(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.18),
                              border: Border.all(color: Colors.white54, width: 1.5),
                            ),
                            child: const Icon(Icons.wb_twilight_rounded,
                                color: Colors.amberAccent, size: 18),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Consumer(
                          builder: (context, ref, _) {
                            final avatar = ref.watch(userAvatarProvider);
                            return _DashboardAvatarButton(avatar: avatar);
                          },
                        ),
                      ],
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

Future<File?> _resolveProfileAvatarFile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('profile_photo_path');
    if (localPath != null && localPath.isNotEmpty) {
      final clean = normalizeLocalPath(localPath) ?? localPath;
      final f = File(clean);
      if (f.existsSync()) return f;
    }
  } catch (_) {}
  return null;
}

class _DashboardAvatarButton extends StatelessWidget {
  final String? avatar;
  const _DashboardAvatarButton({required this.avatar});

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
    );
  }

  Widget _buildFutureFallback() {
    return FutureBuilder<File?>(
      future: _resolveProfileAvatarFile(),
      builder: (context, snapshot) {
        final f = snapshot.data;
        if (f != null && f.existsSync()) {
          return Image.file(
            f,
            width: 34,
            height: 34,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
        }
        return _buildPlaceholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    final clean = normalizeLocalPath(avatar);

    if (clean != null && clean.isNotEmpty) {
      final f = File(clean);
      if (f.existsSync()) {
        content = Image.file(
          f,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } else {
        content = _buildPlaceholder();
      }
    } else if (avatar != null && avatar!.isNotEmpty && avatar!.startsWith('http')) {
      content = Image.network(
        avatar!,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      content = _buildFutureFallback();
    }

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: ClipOval(child: content),
      ),
    );
  }
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
              onTap: () => context.push('/fields'),
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
              onTap: () => context.push('/history'),
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
              onTap: () => context.push('/history'),
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
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.iconBg,
    required this.iconColor,
    required this.waveColor,
    required this.arrowColor,
    this.customIconAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
      final l10n = AppLocalizations.of(context);
      final isNonEnglish = l10n.locale.languageCode != 'en';

      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 305 / 223,
              child: isNonEnglish
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1B4332),
                            Color(0xFF2D6A4F),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Colors.white, size: 26),
                          const SizedBox(height: 5),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  : Image.asset(
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
// ─────────────────────────────────────────────
// RECENT SCANS
// ─────────────────────────────────────────────
class _RecentScans extends ConsumerWidget {
  final AsyncValue<List<ScanModel>> scansAsync;
  final VoidCallback onViewAll, onScan;
  const _RecentScans(
      {required this.scansAsync,
      required this.onViewAll,
      required this.onScan});

  Future<void> _handleDeleteScan(BuildContext context, WidgetRef ref, String scanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete scan?'),
        content: const Text('Are you sure you want to delete this scan result?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ScanRepository(Supabase.instance.client);
      await repo.deleteScan(scanId);
      ref.invalidate(dashboardScansProvider);
      ref.invalidate(dashboardFieldsProvider);
      ref.invalidate(scanHistoryProvider);
    }
  }

  Future<void> _handleClearAll(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all scans?'),
        content: const Text('This will delete all recent scans and history recordings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ScanRepository(Supabase.instance.client);
      await repo.clearAllScans();
      ref.invalidate(dashboardScansProvider);
      ref.invalidate(scanHistoryProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scans = scansAsync.valueOrNull ?? [];

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
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332)),
              ),
              const Spacer(),
              if (scans.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _handleClearAll(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 14, color: Color(0xFFC62828)),
                        SizedBox(width: 4),
                        Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).viewAll,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.chevron_right_rounded,
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
                : _ScansList(
                    scans: scans.take(5).toList(),
                    onDelete: (scanId) => _handleDeleteScan(context, ref, scanId),
                  ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Target only the "Scan now >" button pill in the placeholder:
          // x: 40% -> 83%, y: 67% -> 87%
          final btnLeft = width * 0.40;
          final btnRight = width * 0.17;
          final btnTop = (width / (1869 / 842)) * 0.67;
          final btnHeight = (width / (1869 / 842)) * 0.20;

          return Stack(
            children: [
              Image.asset(
                'assets/images/no_scans_placeholder.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
              Positioned(
                left: btnLeft,
                right: btnRight,
                top: btnTop,
                height: btnHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onScan,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScansList extends StatelessWidget {
  final List<ScanModel> scans;
  final void Function(String scanId) onDelete;
  const _ScansList({required this.scans, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: scans
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8F0E8), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    children: [
                      // Scanned field image thumbnail
                      ScanThumbnailImage(
                        imageUrl: s.imageUrl,
                        createdAt: s.createdAt,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(12),
                        defaultIcon: Icons.grass_rounded,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.weedCount} ${AppLocalizations.of(context).weedsDetected}',
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
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
                      const SizedBox(width: 8),
                      // Delete button at right of each widget
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Color(0xFFC62828)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete scan',
                        onPressed: () => onDelete(s.id),
                      ),
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
  static String weatherEmoji(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'clear':        return '☀️';
      case 'clouds':       return '☁️';
      case 'rain':         return '🌧️';
      case 'drizzle':      return '🌦️';
      case 'thunderstorm': return '⛈️';
      case 'snow':         return '❄️';
      case 'mist':
      case 'fog':          return '🌫️';
      case 'haze':
      case 'smoke':        return '🌤️';
      case 'wind':         return '💨';
      default:             return '⛅';
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
        final emoji     = weatherEmoji(mainStr);

        final l10n = AppLocalizations.of(context);
        final displayDesc = desc.isNotEmpty
            ? l10n.translateWeatherDescription(desc)
            : (mainStr != null ? l10n.translateWeatherCondition(mainStr) : '');

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
                  // Big weather icon + emoji
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
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
                              temp != null ? '${temp.round()}°C' : '--°C',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: iconColor, height: 1),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                displayDesc.isNotEmpty ? _capitalize(displayDesc) : '',
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
                          _WeatherStat(icon: Icons.thermostat_outlined, label: '${l10n.feelsShort} ${feelsLike?.toStringAsFixed(0) ?? '--'}°C', color: iconColor),
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
                        child: Text(l10n.live, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: iconColor)),
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
    {
      'en': 'Apply herbicides early morning or late evening (calm winds & high humidity) for peak absorption.',
      'kn': 'ಉತ್ತಮ ಹೀರಿಕೊಳ್ಳುವಿಕೆಗಾಗಿ ಮುಂಜಾನೆ ಅಥವಾ ಸಂಜೆ ವೇಳೆ (ಶಾಂತ ಗಾಳಿ ಮತ್ತು ಹೆಚ್ಚಿನ ಆರ್ದ್ರತೆ) ಸಸ್ಯನಾಶಕಗಳನ್ನು ಸಿಂಪಡಿಸಿ.',
      'hi': 'सर्वोत्तम अवशोषण के लिए सुबह जल्दी या शाम को (शांत हवा और उच्च आर्द्रता में) शाकनाशी का छिड़काव करें।',
    },
    {
      'en': 'Rotate herbicide mode-of-action groups (HRAC classes) annually to prevent chemical resistance.',
      'kn': 'ರಾಸಾಯನಿಕ ನಿರೋಧಕತೆ ತಡೆಯಲು ವಾರ್ಷಿಕವಾಗಿ ಸಸ್ಯನಾಶಕ ಗುಂಪುಗಳನ್ನು (HRAC ವರ್ಗಗಳು) ಬದಲಾಯಿಸಿ ಬಳಸಿ.',
      'hi': 'रासायनिक प्रतिरोध को रोकने के लिए प्रतिवर्ष शाकनाशी समूहों (HRAC वर्गों) को बदल-बदल कर उपयोग करें।',
    },
    {
      'en': 'Scout fields systematically in a "W" or "Z" pattern weekly during peak emergence periods.',
      'kn': 'ಕಳೆ ಮೊಳಕೆಯೊಡೆಯುವ ಸಮಯದಲ್ಲಿ ವಾರಕ್ಕೊಮ್ಮೆ "W" ಅಥವಾ "Z" ಮಾದರಿಯಲ್ಲಿ ಹೊಲವನ್ನು ಸಂಪೂರ್ಣವಾಗಿ ಪರಿಶೀಲಿಸಿ.',
      'hi': 'खरपतवार उगने के मुख्य समय में साप्ताहिक रूप से "W" या "Z" पैटर्न में खेत का व्यवस्थित निरीक्षण करें।',
    },
    {
      'en': 'Use GPS field mapping to spot and treat localized weed hotspots before they spread.',
      'kn': 'ಕಳೆಗಳು ಹರಡುವ ಮುನ್ನವೇ ಅವುಗಳನ್ನು ಗುರುತಿಸಿ ನಿರ್ವಹಿಸಲು GPS ಹೊಲ ನಕ್ಷೆಯನ್ನು ಬಳಸಿ.',
      'hi': 'खरपतवार फैलने से पहले स्थानीय खरपतवार हॉटस्पॉट की पहचान और उपचार के लिए GPS मैपिंग का उपयोग करें।',
    },
    {
      'en': 'Calibrate sprayer nozzles regularly; worn tips cause uneven coverage and herbicide waste.',
      'kn': 'ಸ್ಪ್ರೇಯರ್ ನಳಿಕೆಗಳನ್ನು ನಿಯಮಿತವಾಗಿ ಪರಿಶೀಲಿಸಿ; ಸವೆದ ತುದಿಯಿಂದ ಅಸಮಾನ ಸಿಂಪರಣೆ ಮತ್ತು ಔಷಧ ವ್ಯರ್ಥವಾಗುತ್ತದೆ.',
      'hi': 'स्प्रेयर नोजल को नियमित रूप से जांचें; घिसे हुए नोजल से छिड़काव असमान होता है और दवा बर्बाद होती है।',
    },
    {
      'en': 'Integrate cereal rye or clover cover crops between seasons to naturally suppress weed seed germination.',
      'kn': 'ಕಳೆ ಬೀಜ ಮೊಳಕೆಯೊಡೆಯುವುದನ್ನು ನೈಸರ್ಗಿಕವಾಗಿ ತಡೆಯಲು ಬೆಳೆಗಳ ನಡುವೆ ಹೊದಿಕೆ ಬೆಳೆಗಳನ್ನು ಬೆಳೆಯಿರಿ.',
      'hi': 'खरपतवार के बीजों को प्राकृतिक रूप से दबाने के लिए फसलों के बीच कवर फसलें (जैसे तिपतिया घास) लगाएं।',
    },
    {
      'en': 'Maintain clean field borders and bunds — weed seed banks travel easily via wind and water.',
      'kn': 'ಹೊಲದ ಬದುಗಳು ಮತ್ತು ಅಂಚುಗಳನ್ನು ಸ್ವಚ್ಛವಾಗಿಡಿ — ಕಳೆ ಬೀಜಗಳು ಗಾಳಿ ಮತ್ತು ನೀರಿನ ಮೂಲಕ ಬೇಗ ಹರಡುತ್ತವೆ.',
      'hi': 'खेत की मेड़ों और सीमाओं को साफ रखें — खरपतवार के बीज हवा और पानी के माध्यम से आसानी से फैलते हैं।',
    },
    {
      'en': 'Deep summer ploughing exposes perennial weed rhizomes and tubers to direct solar heat.',
      'kn': 'ಬೇಸಿಗೆಯ ಆಳವಾದ ಉಳುಮೆಯು ಬಹುವಾರ್ಷಿಕ ಕಳೆಗಳ ಬೇರುಗಳನ್ನು ಸೂರ್ಯನ ಬಿಸಿಲಿಗೆ ಒಡ್ಡಿ ನಾಶಪಡಿಸುತ್ತದೆ.',
      'hi': 'गर्मियों में गहरी जुताई करने से बारहमासी खरपतवारों की जड़ें धूप में सूखकर नष्ट हो जाती हैं।',
    },
    {
      'en': 'Apply pre-emergent herbicides right after rainfall or irrigation when soil moisture is optimal.',
      'kn': 'ಮಣ್ಣಿನಲ್ಲಿ ತೇವಾಂಶ ಉತ್ತಮವಾಗಿರುವಾಗ ಮಳೆ ಅಥವಾ ನೀರಾವರಿಯ ನಂತರವೇ ಪ್ರಿ-ಎಮರ್ಜೆಂಟ್ ಸಸ್ಯನಾಶಕಗಳನ್ನು ಬಳಸಿ.',
      'hi': 'मिट्टी में नमी सही होने पर बारिश या सिंचाई के तुरंत बाद प्री-इमर्जेंट शाकनाशी का छिड़काव करें।',
    },
    {
      'en': 'Ensure sprayer water pH is between 5.5 and 6.5; alkaline water can deactivate glyphosate and glufosinate.',
      'kn': 'ಸಿಂಪರಣಾ ನೀರಿನ pH 5.5 ರಿಂದ 6.5 ಇರಲಿ; ಕ್ಷಾರೀಯ ನೀರು ಗ್ಲೈಫೋಸೇಟ್‌ನಂತಹ ಔಷಧಗಳ ಶಕ್ತಿಯನ್ನು ಕಡಿಮೆ ಮಾಡುತ್ತದೆ.',
      'hi': 'स्प्रे के पानी का pH 5.5 से 6.5 के बीच रखें; क्षारीय पानी ग्लाइफोसेट के प्रभाव को कम कर सकता है।',
    },
    {
      'en': 'Intercropping with leguminous crops provides living mulch and smothers early grass weeds.',
      'kn': 'ದ್ವಿದಳ ಧಾನ್ಯಗಳೊಂದಿಗೆ ಮಿಶ್ರಬೆಳೆ ಬೆಳೆಯುವುದರಿಂದ ನೈಸರ್ಗಿಕ ಹೊದಿಕೆ ಉಂಟಾಗಿ ಕಳೆ ಬೆಳವಣಿಗೆ ತಡೆಯುತ್ತದೆ.',
      'hi': 'दलहनी फसलों के साथ अंतःफसल (इंटरक्रॉपिंग) करने से खरपतवारों की वृद्धि रुकती है।',
    },
    {
      'en': 'Target post-emergent spraying when weeds are in the tender 2-to-4 leaf stage for maximum efficacy.',
      'kn': 'ಗರಿಷ್ಠ ಫಲಿತಾಂಶಕ್ಕಾಗಿ ಕಳೆಗಳು ಎಳೆಯ ೨ ರಿಂದ ೪ ಎಲೆಗಳ ಹಂತದಲ್ಲಿದ್ದಾಗಲೇ ಸಿಂಪರಣೆ ಮಾಡಿ.',
      'hi': 'अधिकतम प्रभाव के लिए खरपतवार जब 2 से 4 पत्तियों की कोमल अवस्था में हों तभी छिड़काव करें।',
    },
    {
      'en': 'Thoroughly wash tractors and harvesters before entering clean fields to stop weed seed transfer.',
      'kn': 'ಕಳೆ ಬೀಜಗಳು ಹರಡದಂತೆ ತಡೆಯಲು ಸ್ವಚ್ಛ ಹೊಲಕ್ಕೆ ಪ್ರವೇಶಿಸುವ ಮುನ್ನ ಟ್ರ್ಯಾಕ್ಟರ್ ಮತ್ತು ಕೊಯ್ಲು ಯಂತ್ರಗಳನ್ನು ತೊಳೆಯಿರಿ.',
      'hi': 'खरपतवार के बीज फैलने से रोकने के लिए स्वच्छ खेत में जाने से पहले ट्रैक्टर और हार्वेस्टर को अच्छी तरह धोएं।',
    },
    {
      'en': 'Incorporate mechanical weeding with a wheel hoe or cultivator between rows before canopy closure.',
      'kn': 'ಬೆಳೆ ಸಾಲುಗಳ ನಡುವೆ ಎಡೆಕುಂಟೆ ಅಥವಾ ವೀಡರ್ ಬಳಸಿ ಯಾಂತ್ರಿಕವಾಗಿ ಕಳೆ ಕೀಳುವುದನ್ನು ರೂಢಿಸಿಕೊಳ್ಳಿ.',
      'hi': 'फसल की कतारों के बीच व्हील हो या कल्टीवेटर से यांत्रिक निराई-गुड़ाई करें।',
    },
    {
      'en': 'Adjust sprayer boom height to 50 cm above crop canopy to prevent drift and ensure uniform overlap.',
      'kn': 'ಗಾಳಿಯಲ್ಲಿ ಔಷಧ ತೇಲಿಹೋಗುವುದನ್ನು ತಡೆಯಲು ಸ್ಪ್ರೇಯರ್ ಎತ್ತರವನ್ನು ಬೆಳೆಯಿಂದ 50 ಸೆಂ.ಮೀ ಮೇಲಿರಿಸಿ.',
      'hi': 'दवा हवा में उड़ने से रोकने और एक समान फैलाव के लिए स्प्रेयर बूम को फसल से 50 सेमी ऊपर रखें।',
    },
    {
      'en': 'Use certified weed-free crop seed lots to prevent introducing noxious foreign weed species.',
      'kn': 'ಹೊಸ ಹಾನಿಕಾರಕ ಕಳೆಗಳು ಬರದಂತೆ ತಡೆಯಲು ಪ್ರಮಾಣೀಕೃತ ಕಳೆ-ಮುಕ್ತ ಬಿತ್ತನೆ ಬೀಜಗಳನ್ನೇ ಬಳಸಿ.',
      'hi': 'अवांछित खरपतवारों से बचने के लिए हमेशा प्रमाणित खरपतवार-मुक्त बीजों का ही उपयोग करें।',
    },
    {
      'en': 'High-density planting narrows inter-row gaps, shading the ground faster and suppressing light-dependent weeds.',
      'kn': 'ಸಾಂದ್ರತೆಯ ಬಿತ್ತನೆಯು ಸಾಲುಗಳ ಅಂತರ ತಗ್ಗಿಸಿ, ನೆರಳು ನೀಡಿ ಕಳೆಗಳ ಬೆಳವಣಿಗೆಯನ್ನು ನಿಗ್ರಹಿಸುತ್ತದೆ.',
      'hi': 'सघन बुवाई से कतारों की दूरी कम होती है, जिससे जमीन पर छाया बनती है और खरपतवार दब जाते हैं।',
    },
    {
      'en': 'Avoid spraying herbicides when wind speed exceeds 10 km/h to prevent spray drift damage.',
      'kn': 'ಗಾಳಿಯ ವೇಗ ಗಂಟೆಗೆ 10 ಕಿ.ಮೀ ಗಿಂತ ಹೆಚ್ಚಿದ್ದಾಗ ಸಸ್ಯನಾಶಕಗಳನ್ನು ಸಿಂಪಡಿಸಬೇಡಿ.',
      'hi': 'हवा की गति 10 किमी/घंटा से अधिक होने पर शाकनाशी का छिड़काव करने से बचें।',
    },
    {
      'en': 'Apply organic straw or plastic mulching in vegetable beds to block weed emergence completely.',
      'kn': 'ತರಕಾರಿ ಮಡಿಗಳಲ್ಲಿ ಕಳೆ ಬರದಂತೆ ತಡೆಯಲು ಒಣ ಹುಲ್ಲು ಅಥವಾ ಪ್ಲಾಸ್ಟಿಕ್ ಮಲ್ಚಿಂಗ್ ಹೊದಿಕೆ ಬಳಸಿ.',
      'hi': 'सब्जियों की क्यारियों में खरपतवार पूरी तरह रोकने के लिए पुआल या प्लास्टिक मल्चिंग का उपयोग करें।',
    },
    {
      'en': 'Destroy weed plants before flowering and seed dispersal to deplete the long-term soil seed bank.',
      'kn': 'ಮಣ್ಣಿನಲ್ಲಿ ಕಳೆ ಬೀಜಗಳು ಶೇಖರಣೆಯಾಗದಂತೆ ತಡೆಯಲು ಹೂ ಬಿಡುವ ಮೊದಲೇ ಕಳೆಗಳನ್ನು ನಾಶಪಡಿಸಿ.',
      'hi': 'मिट्टी में खरपतवार के बीज कम करने के लिए फूल आने और बीज बनने से पहले ही खरपतवार नष्ट करें।',
    },
  ];

  String _getTodaysTip(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final tipMap = _tips[dayOfYear % _tips.length];
    final lang = Localizations.localeOf(context).languageCode;
    return tipMap[lang] ?? tipMap['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tipText = _getTodaysTip(context);

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
                  Text(l10n.farmingTip, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(tipText, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500, height: 1.4)),
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

