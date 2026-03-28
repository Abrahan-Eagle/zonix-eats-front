import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/connectivity_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Sticky banner that appears at the top of the body when the device is offline.
/// Wrap your `Scaffold.body` with this widget or place it inside a [Column].
class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: connectivity.hasNetwork
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.red,
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: AppColors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin conexión. Mostrando datos guardados.',
                              style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
