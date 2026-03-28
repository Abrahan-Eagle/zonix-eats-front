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
        final offline = !connectivity.hasNetwork;
        final degraded = connectivity.hasNetwork && !connectivity.apiReachable;
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: offline
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.red,
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: AppColors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin conexión a internet',
                              style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )
                  : degraded
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: AppColors.orange.withValues(alpha: 0.15),
                          child: const Row(
                            children: [
                              Icon(Icons.signal_wifi_statusbar_connected_no_internet_4, color: AppColors.orange, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Conexión inestable — algunos datos pueden no estar actualizados',
                                  style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
