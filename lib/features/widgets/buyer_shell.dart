import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/location/location_search_page.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/screens/settings/settings_page_2.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';

/// Shell para flujo comprador: header "Delivering to" + bottom nav estilo template Stitch.
/// Soporta tema light y dark.
class BuyerShell extends StatefulWidget {
  final Widget child;
  /// Si false, no muestra el bottom nav (usa el de main.dart)
  final bool showBottomNav;
  final int currentIndex;
  final ValueChanged<int>? onNavTap;

  const BuyerShell({
    super.key,
    required this.child,
    this.showBottomNav = false,
    this.currentIndex = 0,
    this.onNavTap,
  });

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int _addressReloadKey = 0;
  int _unreadNotifications = 0;

  static const Color _primary = Color(0xFF3399FF);
  static const Color _navActive = Color(0xFF3299FF);
  static const Color _navBg = Color(0xFF1A2E46);
  static const Color _bgLight = Color(0xFFF5F7F8);
  static const Color _bgDark = Color(0xFF0F1923);
  static const Color _badgeRed = Color(0xFFE53935);

  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final data = await _notificationService.getNotificationCount();
      if (!mounted) return;
      setState(() {
        _unreadNotifications = (data['unread'] as int?) ?? 0;
      });
    } catch (_) {
      // Silenciar fallo; el icono se muestra sin badge
    }
  }

  Future<void> _loadDeliveryAddress() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (!mounted) return;
      final label = loc['address'] as String?;
      if (label != null && label.isNotEmpty) {
        await context.read<SearchRadiusProvider>().setDeliveryAddressLabel(label);
      }
    } catch (_) {
      // Silenciar fallo de ubicación
    }
  }

  Future<void> _onAddressTap() async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LocationSearchPage()),
    );
    if (applied == true && mounted) {
      _loadDeliveryAddress();
      setState(() => _addressReloadKey++);
    }
  }

  void _onNotificationTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    ).then((_) => _loadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildHeader(context, isDark),
        Expanded(
          child: KeyedSubtree(
            key: ValueKey(_addressReloadKey),
            child: widget.child,
          ),
        ),
        if (widget.showBottomNav) _buildBottomNav(context, isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final radiusProvider = context.watch<SearchRadiusProvider>();
    final addressLabel = radiusProvider.deliveryAddressLabel ?? 'Cargando ubicación...';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 12,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: (isDark ? _bgDark : _bgLight).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: _primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _onAddressTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: _primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entregando a',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              addressLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F1923),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.expand_more, color: _primary, size: 20),
                    ],
                  ),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _onNotificationTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      Icons.notifications_none,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 26,
                    ),
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: _unreadNotifications > 9
                            ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                            : const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: _badgeRed,
                          shape: _unreadNotifications > 9 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: _unreadNotifications > 9 ? BorderRadius.circular(10) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final items = [
      (icon: Icons.explore, label: 'Explorar'),
      (icon: Icons.shopping_cart, label: 'Carrito'),
      (icon: Icons.receipt_long, label: 'Órdenes'),
      (icon: Icons.storefront, label: 'Restaurantes'),
      (icon: Icons.person, label: 'Perfil'),
      (icon: Icons.settings, label: 'Configuración'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _navBg.withValues(alpha: 0.95) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = widget.currentIndex == i;
              final item = items[i];
              final isConfig = i == items.length - 1;
              return InkWell(
                onTap: () {
                  if (isConfig) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage2()));
                  } else {
                    widget.onNavTap?.call(i);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: selected ? _navActive : (isDark ? Colors.white54 : Colors.black45),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? _navActive : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
