import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F0),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header: cropped top of template image only ──────────────
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFFF5F6F0), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Account ─────────────────────────────────────────────────
          _Section(icon: Icons.person_outline_rounded, title: 'Account', items: [
            _Tile(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () => context.push('/profile')),
          ]),

          // ── Application ─────────────────────────────────────────────
          _Section(icon: Icons.tune_rounded, title: 'Application', items: [
            _Tile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
            _Tile(
              icon: Icons.language_outlined, label: 'Language',
              trailing: const Text('English', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
              onTap: () {},
            ),
            _Tile(
              icon: Icons.straighten_outlined, label: 'Units',
              trailing: const Text('Metric', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
              onTap: () {},
            ),
          ]),

          // ── About ───────────────────────────────────────────────────
          _Section(icon: Icons.info_outline_rounded, title: 'About', items: [
            _Tile(icon: Icons.privacy_tip_outlined, label: 'Privacy policy', onTap: () {}),
            _Tile(
              icon: Icons.info_outline_rounded, label: 'App version',
              trailing: Text(AppConstants.appVersion, style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
              onTap: null,
            ),
          ]),

          // ── Sign out ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                label: const Text('Sign out',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
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

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> items;
  const _Section({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EFE8)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1)
                const Divider(indent: 56, endIndent: 0, height: 0, thickness: 0.8, color: Color(0xFFF0F4F0)),
            ],
          ]),
        ),
      ]),
    );
  }
}

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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1B4332)))),
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
