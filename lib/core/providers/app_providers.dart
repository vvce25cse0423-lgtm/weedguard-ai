import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Theme Provider ────────────────────────────────────────────────────────────
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  ThemeModeNotifier() : super(ThemeMode.light) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key) ?? 'light';
    state = val == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

// ── Locale Provider ───────────────────────────────────────────────────────────
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'locale_lang';
  LocaleNotifier() : super(const Locale('en')) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key) ?? 'en';
    state = Locale(val);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

// ── Units Provider ────────────────────────────────────────────────────────────
final unitsProvider = StateNotifierProvider<UnitsNotifier, String>((ref) {
  return UnitsNotifier();
});

class UnitsNotifier extends StateNotifier<String> {
  static const _key = 'units_system';
  UnitsNotifier() : super('metric') { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? 'metric';
  }

  Future<void> setUnits(String units) async {
    state = units;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, units);
  }
}

// ── User Avatar Provider ──────────────────────────────────────────────────────
final userAvatarProvider = StateNotifierProvider<UserAvatarNotifier, String?>((ref) {
  return UserAvatarNotifier();
});

class UserAvatarNotifier extends StateNotifier<String?> {
  static const _keyPath = 'profile_photo_path';
  static const _keyUrl = 'profile_photo_url';

  UserAvatarNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString(_keyPath);
      if (localPath != null && localPath.isNotEmpty) {
        final clean = localPath.replaceFirst(RegExp(r'^file://'), '');
        if (File(clean).existsSync()) {
          state = clean;
          return;
        }
      }

      // Check app directory for saved profile avatar files
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('profile_avatar_'))
          .toList();
      if (files.isNotEmpty) {
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        state = files.first.path;
        await prefs.setString(_keyPath, files.first.path);
        return;
      }

      final remoteUrl = prefs.getString(_keyUrl);
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        state = remoteUrl;
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      final metaAvatar = user?.userMetadata?['avatar_url'] as String?;
      if (metaAvatar != null && metaAvatar.isNotEmpty) {
        state = metaAvatar;
      }
    } catch (_) {}
  }

  Future<void> setAvatar(String? pathOrUrl) async {
    state = pathOrUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pathOrUrl == null || pathOrUrl.isEmpty) {
        await prefs.remove(_keyPath);
        await prefs.remove(_keyUrl);
      } else if (pathOrUrl.startsWith('http')) {
        await prefs.setString(_keyUrl, pathOrUrl);
      } else {
        final clean = pathOrUrl.replaceFirst(RegExp(r'^file://'), '');
        await prefs.setString(_keyPath, clean);
      }
    } catch (_) {}
  }
}
