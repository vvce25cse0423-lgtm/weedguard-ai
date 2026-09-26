class AppConstants {
  AppConstants._();

  static const String appName = 'WeedGuard';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = 'https://yphhjjunhtqpazvxfhgo.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Y9LPePWF1tgrckpyd-JtaA_rG4cRXmA';

  // OpenWeather (used in weather edge function via Supabase secret, also stored here for reference)
  static const String openWeatherApiKey = '624d64f50bcf3cf596ccf7693dce142f';

  // Weather Edge Function
  static const String weatherFunctionName = 'weather';

  // Storage buckets
  static const String scanImagesBucket = 'scan-images';
  static const String profileImagesBucket = 'profile-images';

  // Severity thresholds
  static const double severityLowMax = 0.3;
  static const double severityModerateMax = 0.6;

  // Max image file size: 10 MB
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  // Zone labels
  static const List<String> zoneLabels = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];

  // Demo mode
  static const bool isDemoMode = false;
}
