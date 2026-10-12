import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

const _owmApiKey = '624d64f50bcf3cf596ccf7693dce142f';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  // Selected or active location
  String _currentCity = 'Bengaluru';
  double _lat = 12.9716;
  double _lon = 77.5946;

  // Curated prominent agricultural and major Indian/world cities for instant suggestions
  final List<Map<String, dynamic>> _cityDirectory = [
    {'name': 'Bengaluru', 'state': 'Karnataka', 'country': 'India', 'lat': 12.9716, 'lon': 77.5946},
    {'name': 'Mysuru', 'state': 'Karnataka', 'country': 'India', 'lat': 12.2958, 'lon': 76.6394},
    {'name': 'Mandya', 'state': 'Karnataka', 'country': 'India', 'lat': 12.5244, 'lon': 76.8958},
    {'name': 'Hassan', 'state': 'Karnataka', 'country': 'India', 'lat': 13.0033, 'lon': 76.1004},
    {'name': 'Shivamogga', 'state': 'Karnataka', 'country': 'India', 'lat': 13.9299, 'lon': 75.5681},
    {'name': 'Hubballi', 'state': 'Karnataka', 'country': 'India', 'lat': 15.3647, 'lon': 75.1240},
    {'name': 'Belagavi', 'state': 'Karnataka', 'country': 'India', 'lat': 15.8497, 'lon': 74.4977},
    {'name': 'Tumakuru', 'state': 'Karnataka', 'country': 'India', 'lat': 13.3379, 'lon': 77.1010},
    {'name': 'Ballari', 'state': 'Karnataka', 'country': 'India', 'lat': 15.1394, 'lon': 76.9214},
    {'name': 'Kalaburagi', 'state': 'Karnataka', 'country': 'India', 'lat': 17.3297, 'lon': 76.8343},
    {'name': 'Hyderabad', 'state': 'Telangana', 'country': 'India', 'lat': 17.3850, 'lon': 78.4867},
    {'name': 'Chennai', 'state': 'Tamil Nadu', 'country': 'India', 'lat': 13.0827, 'lon': 80.2707},
    {'name': 'Coimbatore', 'state': 'Tamil Nadu', 'country': 'India', 'lat': 11.0168, 'lon': 76.9558},
    {'name': 'Pune', 'state': 'Maharashtra', 'country': 'India', 'lat': 18.5204, 'lon': 73.8567},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'country': 'India', 'lat': 19.0760, 'lon': 72.8777},
    {'name': 'Nagpur', 'state': 'Maharashtra', 'country': 'India', 'lat': 21.1458, 'lon': 79.0882},
    {'name': 'Delhi', 'state': 'Delhi', 'country': 'India', 'lat': 28.6139, 'lon': 77.2090},
    {'name': 'Ludhiana', 'state': 'Punjab', 'country': 'India', 'lat': 30.9010, 'lon': 75.8573},
    {'name': 'Jaipur', 'state': 'Rajasthan', 'country': 'India', 'lat': 26.9124, 'lon': 75.7873},
    {'name': 'Indore', 'state': 'Madhya Pradesh', 'country': 'India', 'lat': 22.7196, 'lon': 75.8577},
    {'name': 'Ahmedabad', 'state': 'Gujarat', 'country': 'India', 'lat': 23.0225, 'lon': 72.5714},
    {'name': 'Kolkata', 'state': 'West Bengal', 'country': 'India', 'lat': 22.5726, 'lon': 88.3639},
  ];

  @override
  void initState() {
    super.initState();
    // Auto-detect current device GPS location on launch
    _fetchDeviceGpsLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final matches = _cityDirectory.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final state = (c['state'] as String).toLowerCase();
      return name.contains(q) || state.contains(q);
    }).toList();

    setState(() {
      _suggestions = matches;
      _showSuggestions = matches.isNotEmpty;
    });
  }

  String _cleanPlaceName(String raw) {
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

  Future<String> _resolveCityName(double lat, double lon, String? fallback) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/reverse?lat=&lon=&limit=5&appid=',
      );
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();

      final list = jsonDecode(body) as List?;
      if (list != null && list.isNotEmpty) {
        final first = list.first as Map<String, dynamic>?;
        final name = first?['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return _cleanPlaceName(name);
        }
      }
    } catch (_) {}
    return fallback != null ? _cleanPlaceName(fallback) : 'Your Location';
  }

  Future<void> _fetchWeatherForCoords(double lat, double lon, {String? cityName}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showSuggestions = false;
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=&lon=&appid=&units=metric',
      );
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['cod'] != 200 && json['cod'] != '200') {
        throw Exception(json['message'] ?? 'Unable to fetch weather');
      }

      final main = json['main'] as Map<String, dynamic>?;
      final wind = json['wind'] as Map<String, dynamic>?;
      final weatherList = json['weather'] as List?;
      final weather = weatherList != null && weatherList.isNotEmpty
          ? weatherList.first as Map<String, dynamic>?
          : null;
      final clouds = json['clouds'] as Map<String, dynamic>?;
      final sys = json['sys'] as Map<String, dynamic>?;

      String resolvedCity = cityName ?? '';
      if (resolvedCity.isEmpty) {
        resolvedCity = await _resolveCityName(lat, lon, json['name'] as String?);
      }

      setState(() {
        _lat = lat;
        _lon = lon;
        _currentCity = resolvedCity;
        _weatherData = {
          'temp': main?['temp'],
          'feels_like': main?['feels_like'],
          'temp_min': main?['temp_min'],
          'temp_max': main?['temp_max'],
          'humidity': main?['humidity'],
          'pressure': main?['pressure'],
          'wind_speed': wind?['speed'],
          'wind_deg': wind?['deg'],
          'desc': weather?['description'],
          'main': weather?['main'],
          'icon': weather?['icon'],
          'clouds': clouds?['all'],
          'city': resolvedCity,
          'country': sys?['country'],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not load weather data for this location.';
      });
    }
  }

  Future<void> _fetchWeatherByCityName(String cityName) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showSuggestions = false;
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(cityName)}&appid=$_owmApiKey&units=metric',
      );
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['cod'] != 200 && json['cod'] != '200') {
        throw Exception(json['message'] ?? 'City not found');
      }

      final coord = json['coord'] as Map<String, dynamic>?;
      final main = json['main'] as Map<String, dynamic>?;
      final wind = json['wind'] as Map<String, dynamic>?;
      final weatherList = json['weather'] as List?;
      final weather = weatherList != null && weatherList.isNotEmpty
          ? weatherList.first as Map<String, dynamic>?
          : null;
      final clouds = json['clouds'] as Map<String, dynamic>?;
      final sys = json['sys'] as Map<String, dynamic>?;

      setState(() {
        _currentCity = json['name'] as String? ?? cityName;
        _lat = (coord?['lat'] as num?)?.toDouble() ?? _lat;
        _lon = (coord?['lon'] as num?)?.toDouble() ?? _lon;
        _weatherData = {
          'temp': main?['temp'],
          'feels_like': main?['feels_like'],
          'temp_min': main?['temp_min'],
          'temp_max': main?['temp_max'],
          'humidity': main?['humidity'],
          'pressure': main?['pressure'],
          'wind_speed': wind?['speed'],
          'wind_deg': wind?['deg'],
          'desc': weather?['description'],
          'main': weather?['main'],
          'icon': weather?['icon'],
          'clouds': clouds?['all'],
          'city': json['name'] ?? cityName,
          'country': sys?['country'],
        };
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Location not found. Try searching another city or use GPS.';
      });
    }
  }

  Future<void> _fetchDeviceGpsLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showSuggestions = false;
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _error = 'Location permission is denied. Enable it in settings.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _searchCtrl.clear();
      await _fetchWeatherForCoords(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to fetch current GPS location. Please check GPS settings.';
      });
    }
  }

  /// Spraying Advisory Logic based on agricultural temperature, wind, and humidity
  Map<String, dynamic> _calculateSprayAdvisory(double temp, double windSpeed, double humidity, String condition) {
    final condLower = condition.toLowerCase();
    final isRaining = condLower.contains('rain') || condLower.contains('drizzle') || condLower.contains('thunderstorm');

    if (isRaining) {
      return {
        'status': 'DO NOT SPRAY',
        'isGood': false,
        'badgeColor': const Color(0xFFC62828),
        'bgColor': const Color(0xFFFFEBEE),
        'title': 'High Rain Risk — Herbicide Wash-off',
        'advice': 'Active precipitation will wash away herbicides into runoff. Wait until rainfall stops and foliage dries completely.',
        'bestTime': 'Postpone application by 24-48 hours until sunny conditions return.',
      };
    }

    if (temp > 32) {
      return {
        'status': 'SPRAYING NOT RECOMMENDED',
        'isGood': false,
        'badgeColor': const Color(0xFFE65100),
        'bgColor': const Color(0xFFFFF3E0),
        'title': 'High Temperature Alert (>32°C)',
        'advice': 'High temperatures cause rapid herbicide droplet evaporation and severe crop phototoxicity/leaf burn.',
        'bestTime': 'Spray during early morning hours (6:00 AM – 9:00 AM) or evening after 5:30 PM.',
      };
    }

    if (temp < 15) {
      return {
        'status': 'POOR SPRAY CONDITIONS',
        'isGood': false,
        'badgeColor': const Color(0xFFF57F17),
        'bgColor': const Color(0xFFFFFDE7),
        'title': 'Low Temperature Alert (<15°C)',
        'advice': 'Weed metabolism slows significantly in cold temperatures, reducing systemic herbicide absorption.',
        'bestTime': 'Wait until mid-morning (10:00 AM – 1:00 PM) when solar warming increases.',
      };
    }

    if (windSpeed > 4.5) {
      return {
        'status': 'HIGH DRIFT RISK',
        'isGood': false,
        'badgeColor': const Color(0xFFD84315),
        'bgColor': const Color(0xFFFBE9E7),
        'title': 'High Wind Speed (${windSpeed.toStringAsFixed(1)} m/s)',
        'advice': 'Wind exceeding 4.5 m/s causes spray drift onto neighboring sensitive crops and uneven coverage.',
        'bestTime': 'Spray during early morning or late evening when thermal air calm prevails.',
      };
    }

    if (humidity < 40) {
      return {
        'status': 'MODERATE CONDITIONS',
        'isGood': true,
        'badgeColor': const Color(0xFFF57F17),
        'bgColor': const Color(0xFFFFFDE7),
        'title': 'Low Humidity (<40%)',
        'advice': 'Low relative humidity accelerates droplet evaporation before weed foliar penetration. Use larger droplet nozzles.',
        'bestTime': 'Early morning (6:30 AM – 9:00 AM) when dew and atmospheric moisture are optimal.',
      };
    }

    // Optimal conditions
    return {
      'status': 'EXCELLENT TO SPRAY',
      'isGood': true,
      'badgeColor': const Color(0xFF2E7D32),
      'bgColor': const Color(0xFFE8F5E9),
      'title': 'Ideal Herbicide Application Window',
      'advice': 'Optimal temperature (18°C–28°C), gentle wind (<3 m/s), and suitable humidity ensure maximum systemic uptake and weed kill.',
      'bestTime': 'Active window right now through early evening (until 5:00 PM). Ensure calm breeze.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final temp = (_weatherData?['temp'] as num?)?.toDouble() ?? 26.0;
    final wind = (_weatherData?['wind_speed'] as num?)?.toDouble() ?? 2.2;
    final humidity = (_weatherData?['humidity'] as num?)?.toDouble() ?? 62.0;
    final condition = (_weatherData?['main'] as String?) ?? 'Clear';
    final desc = (_weatherData?['desc'] as String?) ?? 'clear sky';
    final advisory = _calculateSprayAdvisory(temp, wind, humidity, condition);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Weather & Spray Advisory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Weather Overview Card ─────────────────────────────────────────
                _buildWeatherCard(temp, desc, condition, wind, humidity),
                const SizedBox(height: 20),

                // ── Herbicide Spray Advisory Card ─────────────────────────────────
                _buildSprayAdvisoryCard(advisory, temp, wind, humidity),
                const SizedBox(height: 20),

                // ── Spraying Guidelines & Best Practices ──────────────────────────
                _buildBestPracticesCard(),
              ],
            ),
          ),

          // ── Search & GPS Bar Fixed at Top ───────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.search_rounded, color: Color(0xFF2D6A4F), size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              _fetchWeatherByCityName(v.trim());
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search city or farm location...',
                            hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF757575)),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        ),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFE0E0E0),
                      ),
                      IconButton(
                        tooltip: 'Detect current location via GPS',
                        icon: const Icon(Icons.my_location_rounded, color: Color(0xFF2D6A4F), size: 22),
                        onPressed: _fetchDeviceGpsLocation,
                      ),
                    ],
                  ),
                ),

                // ── Instant Suggestions Dropdown ──────────────────────────────
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD8F3DC)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F4F0)),
                      itemBuilder: (context, i) {
                        final item = _suggestions[i];
                        final name = item['name'] as String;
                        final state = item['state'] as String;
                        final lat = item['lat'] as double;
                        final lon = item['lon'] as double;

                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFF2D6A4F), size: 20),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1B4332)),
                          ),
                          subtitle: Text(
                            '$state, India',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B8F71)),
                          ),
                          onTap: () {
                            _searchCtrl.text = name;
                            _fetchWeatherForCoords(lat, lon, cityName: name);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(double temp, String desc, String condition, double wind, double humidity) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF95D5B2), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _currentCity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  condition,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${temp.round()}°C',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF95D5B2),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like ${((_weatherData?['feels_like'] as num?)?.toDouble() ?? temp).round()}°C',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMiniStat(Icons.water_drop_outlined, 'Humidity', '${humidity.round()}%'),
                _buildWeatherDivider(),
                _buildWeatherMiniStat(Icons.air_rounded, 'Wind Speed', '${wind.toStringAsFixed(1)} m/s'),
                _buildWeatherDivider(),
                _buildWeatherMiniStat(Icons.compress_rounded, 'Pressure', '${_weatherData?['pressure'] ?? 1012} hPa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDivider() {
    return Container(height: 28, width: 1, color: Colors.white24);
  }

  Widget _buildWeatherMiniStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF95D5B2)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _buildSprayAdvisoryCard(Map<String, dynamic> advisory, double temp, double wind, double humidity) {
    final badgeColor = advisory['badgeColor'] as Color;
    final bgColor = advisory['bgColor'] as Color;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      advisory['isGood'] ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: badgeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      advisory['status'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.science_outlined, color: Color(0xFF2D6A4F), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            advisory['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            advisory['advice'],
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF40624F),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8F3DC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF2D6A4F), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Spray Window',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        advisory['bestTime'],
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B4332), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPracticesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F0E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: Color(0xFF2D6A4F), size: 20),
              SizedBox(width: 8),
              Text(
                'Agronomy Spray Rules',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildBulletItem(
            'Target Temperature: 18°C – 28°C',
            'Herbicide uptake is highest when weed stomata are actively open and plants are unstressed.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            'Wind Speed Limit: < 4 m/s',
            'Strong wind causes drift onto non-target crops. Never spray in gusty conditions.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            'Dew & Foliage Moisture',
            'Avoid spraying when leaves are drenched in heavy water droplets to prevent formulation runoff.',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF2D6A4F),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B8F71), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
