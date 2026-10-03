import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/fields/presentation/screens/fields_list_screen.dart';
import '../../features/fields/presentation/screens/field_detail_screen.dart';
import '../../features/fields/presentation/screens/create_field_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/detection/presentation/screens/detection_result_screen.dart';
import '../../features/history/presentation/screens/scan_history_screen.dart';
import '../../features/comparison/presentation/screens/scan_comparison_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/models/detection_result_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/fields', builder: (_, __) => const FieldsListScreen()),
          GoRoute(path: '/fields/new', builder: (_, __) => const CreateFieldScreen()),
          GoRoute(
            path: '/fields/:id',
            builder: (_, state) => FieldDetailScreen(fieldId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/fields/:id/edit',
            builder: (_, state) => CreateFieldScreen(fieldId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/scanner',
            builder: (_, state) {
              final fieldId = state.uri.queryParameters['fieldId'];
              return ScannerScreen(fieldId: fieldId);
            },
          ),
          GoRoute(
            path: '/detection-result',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return DetectionResultScreen(
                result: extra['result'] as WeedDetectionResult,
                fieldId: extra['fieldId'] as String,
                scanId: extra['scanId'] as String?,
              );
            },
          ),
          GoRoute(path: '/history', builder: (_, __) => const ScanHistoryScreen()),
          GoRoute(
            path: '/comparison',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ScanComparisonScreen(
                previousScanId: extra?['previousScanId'] as String?,
                currentScanId: extra?['currentScanId'] as String?,
              );
            },
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _routes = ['/', '/fields', '/history', '/settings'];

  int _indexFromLocation(String location) {
    if (location.startsWith('/fields')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
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
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                        context.go('/');
                      },
                    ),
                    _NavItem(
                      icon: Icons.grass_rounded,
                      label: 'Fields',
                      isActive: currentIndex == 1,
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                        context.go('/fields');
                      },
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      isActive: currentIndex == 2,
                      onTap: () {
                        setState(() => _selectedIndex = 2);
                        context.go('/history');
                      },
                    ),
                    _NavItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      isActive: currentIndex == 3,
                      onTap: () {
                        setState(() => _selectedIndex = 3);
                        context.go('/settings');
                      },
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
