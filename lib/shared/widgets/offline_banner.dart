import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectivityStreamProvider);
    return conn.maybeWhen(
      data: (isOnline) => isOnline
          ? const SizedBox.shrink()
          : Container(
              color: AppColors.severityModerate,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('No connection — changes will sync when reconnected.', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
