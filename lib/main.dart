import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yphhjjunhtqpazvxfhgo.supabase.co',
    anonKey: 'sb_publishable_Y9LPePWF1tgrckpyd-JtaA_rG4cRXmA',
  );

  runApp(const ProviderScope(child: WeedGuardApp()));
}

class WeedGuardApp extends ConsumerWidget {
  const WeedGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'WeedGuard',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
