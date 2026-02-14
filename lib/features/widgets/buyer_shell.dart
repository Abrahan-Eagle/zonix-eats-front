import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/location/location_search_page.dart';
import 'package:zonix/features/screens/settings/settings_page_2.dart';
import 'package:zonix/features/services/location_service.dart';
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

  static const Color _primary = Color(0xFF3399FF);
  static const Color _navActive = Color(0xFF3299FF);
  static const Color _navBg = Color(0xFF1A2E46);
  static const Color _bgLight = Color(0xFFF5F7F8);
  static const Color _bgDark = Color(0xFF0F1923);

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
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
    // Solo notificaciones; Configuración está en el tab del bottom nav
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
        bottom: 16,
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
                        child: Icon(Icons.location_on, color: _primary, size: 22),
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
                      Icon(Icons.expand_more, color: _primary, size: 20),
                    ],
                  ),
                ),
              ),
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
