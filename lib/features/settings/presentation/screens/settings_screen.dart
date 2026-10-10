import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutConfirm),
        content: Text(l10n.signOutMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.selectLanguage,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _LangOption(
              flag: '🇬🇧', label: 'English', sublabel: 'English',
              selected: currentLocale.languageCode == 'en',
              onTap: () { ref.read(localeProvider.notifier).setLocale(const Locale('en')); Navigator.pop(ctx); },
            ),
            const Divider(height: 1),
            _LangOption(
              flag: '🇮🇳', label: 'ಕನ್ನಡ', sublabel: 'Kannada',
              selected: currentLocale.languageCode == 'kn',
              onTap: () { ref.read(localeProvider.notifier).setLocale(const Locale('kn')); Navigator.pop(ctx); },
            ),
            const Divider(height: 1),
            _LangOption(
              flag: '🇮🇳', label: 'हिंदी', sublabel: 'Hindi',
              selected: currentLocale.languageCode == 'hi',
              onTap: () { ref.read(localeProvider.notifier).setLocale(const Locale('hi')); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notifications),
        content: const _NotificationSettings(),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.done)),
        ],
      ),
    );
  }

  void _showUnitsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.units),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Row(children: [
              Icon(Icons.check, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 8),
              Text('Metric (kg, ha, km)'),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Padding(
              padding: EdgeInsets.only(left: 26),
              child: Text('Imperial (lb, acre, mi)'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.privacyPolicy),
        content: const SingleChildScrollView(
          child: Text(
            'WeedGuard AI collects field images and location data solely to provide weed detection services.\n\n'
            'Your data is stored securely and never shared with third parties.\n\n'
            'Images are processed by AI models and may be used to improve detection accuracy.\n\n'
            'You may delete your account and all associated data at any time from this settings screen.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.done)),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString('groq_api_key') ?? prefs.getString('openrouter_api_key') ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Groq AI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Groq API key (starts with gsk_...) for cloud AI vision inference. If empty or unavailable, on-device vision analysis runs automatically.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'gsk_...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text.trim();
              await prefs.setString('groq_api_key', val);
              await prefs.setString('openrouter_api_key', val);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final topPad = MediaQuery.of(context).padding.top;

    final langLabel = locale.languageCode == 'kn'
        ? 'ಕನ್ನಡ'
        : locale.languageCode == 'hi'
            ? 'हिंदी'
            : 'English';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 110 + topPad,
                child: Image.asset(
                  'assets/images/settings_header.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Theme.of(context).scaffoldBackgroundColor, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Account ─────────────────────────────────────────────────
          _Section(title: l10n.account, icon: Icons.person_outline_rounded, items: [
            _Tile(
              icon: Icons.person_outline_rounded,
              label: l10n.profile,
              onTap: () => context.push('/profile'),
            ),
          ]),

          // ── Application ─────────────────────────────────────────────
          _Section(title: l10n.application, icon: Icons.tune_rounded, items: [
            _Tile(
              icon: Icons.notifications_outlined,
              label: l10n.notifications,
              onTap: () => _showNotificationsDialog(context),
            ),
            _Tile(
              icon: Icons.language_outlined,
              label: l10n.language,
              trailing: Text(langLabel,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              onTap: () => _showLanguagePicker(context, ref),
            ),
            _DarkModeTile(
              label: l10n.darkMode,
              isDark: isDark,
              onChanged: (val) => ref.read(themeModeProvider.notifier)
                  .setMode(val ? ThemeMode.dark : ThemeMode.light),
            ),
            _Tile(
              icon: Icons.straighten_outlined,
              label: l10n.units,
              trailing: Text(l10n.metric,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              onTap: () => _showUnitsDialog(context),
            ),
            _Tile(
              icon: Icons.vpn_key_outlined,
              label: 'Groq AI API Key',
              onTap: () => _showApiKeyDialog(context),
            ),
          ]),

          // ── About ───────────────────────────────────────────────────
          _Section(title: l10n.about, icon: Icons.info_outline_rounded, items: [
            _Tile(
              icon: Icons.privacy_tip_outlined,
              label: l10n.privacyPolicy,
              onTap: () => _showPrivacyPolicy(context),
            ),
            _Tile(
              icon: Icons.info_outline_rounded,
              label: l10n.appVersion,
              trailing: Text(AppConstants.appVersion,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              onTap: null,
            ),
          ]),

          // ── Sign out ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                label: Text(l10n.signOut,
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFFFF0EE),
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Language Option ───────────────────────────────────────────────────────────
class _LangOption extends StatelessWidget {
  final String flag, label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _LangOption({required this.flag, required this.label, required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(sublabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ])),
          if (selected) const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
        ]),
      ),
    );
  }
}

// ── Notification Settings ─────────────────────────────────────────────────────
class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings();
  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  bool scanAlerts = true;
  bool weeklyReport = false;
  bool weatherAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Scan Alerts'), value: scanAlerts, onChanged: (v) => setState(() => scanAlerts = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Weekly Report'), value: weeklyReport, onChanged: (v) => setState(() => weeklyReport = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Weather Alerts'), value: weatherAlerts, onChanged: (v) => setState(() => weatherAlerts = v)),
    ]);
  }
}

// ── Section ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> items;
  const _Section({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE8EFE8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 14),
          child: Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF6B8F71)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B8F71), letterSpacing: 0.3)),
            const SizedBox(width: 8),
            const Expanded(child: Divider(color: Color(0xFFCFDFCF), thickness: 1)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1) Divider(indent: 56, endIndent: 0, height: 0, thickness: 0.8, color: borderColor),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Dark Mode Tile ────────────────────────────────────────────────────────────
class _DarkModeTile extends StatelessWidget {
  final String label;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _DarkModeTile({required this.label, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF2D6A4F), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        Switch.adaptive(
          value: isDark,
          onChanged: onChanged,
          activeColor: const Color(0xFF2E7D32),
        ),
      ]),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF2D6A4F), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          if (trailing != null) trailing!,
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD), size: 20),
          ],
        ]),
      ),
    );
  }
}
