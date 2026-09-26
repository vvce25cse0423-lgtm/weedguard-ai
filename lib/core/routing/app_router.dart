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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          context.go(_routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Fields',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
