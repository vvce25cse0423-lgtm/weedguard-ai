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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Account',
            items: [
              _SettingsTile(icon: Icons.person_outline, label: 'Profile', onTap: () => context.push('/profile')),
            ],
          ),
          _SettingsSection(
            title: 'Application',
            items: [
              _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
              _SettingsTile(icon: Icons.language_outlined, label: 'Language', trailing: const Text('English'), onTap: () {}),
              _SettingsTile(icon: Icons.straighten_outlined, label: 'Units', trailing: const Text('Metric'), onTap: () {}),
            ],
          ),
          _SettingsSection(
            title: 'About',
            items: [
              _SettingsTile(icon: Icons.privacy_tip_outlined, label: 'Privacy policy', onTap: () {}),
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'App version',
                trailing: Text(AppConstants.appVersion, style: const TextStyle(color: AppColors.textSecondary)),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
        ),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1) const Divider(indent: 52, height: 0),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textDisabled) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
