import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/app/notification_navigation.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/screens/admin/admin_analytics_page.dart';
import 'package:zonix/features/screens/admin/admin_dashboard_page.dart';
import 'package:zonix/features/screens/admin/admin_orders_page.dart';
import 'package:zonix/features/screens/admin/admin_users_page.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';
import 'package:zonix/features/screens/commerce/commerce_dashboard_page.dart';
import 'package:zonix/features/screens/commerce/commerce_orders_page.dart';
import 'package:zonix/features/screens/commerce/commerce_products_page.dart';
import 'package:zonix/features/screens/commerce/commerce_reports_page.dart';
import 'package:zonix/features/screens/delivery/delivery_earnings_page.dart';
import 'package:zonix/features/screens/delivery/delivery_history_page.dart';
import 'package:zonix/features/screens/delivery/delivery_orders_page.dart';
import 'package:zonix/features/screens/delivery/delivery_routes_page.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_agents_page.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_dashboard_page.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_map_page.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_orders_page.dart';
import 'package:zonix/features/screens/location/location_search_page.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/screens/orders/orders_page.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/features/screens/restaurants/restaurants_page.dart';
import 'package:zonix/features/screens/restaurants/restaurant_details_page.dart';
import 'package:zonix/features/services/restaurant_service.dart';
import 'package:zonix/features/utils/storefront_qr_pending.dart';
import 'package:zonix/features/screens/settings/settings_page_2.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/app_theme.dart';
import 'package:zonix/features/utils/bottom_nav_persistence.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/widgets/buyer_shell.dart';
import 'package:zonix/models/notification_item.dart';
import 'package:zonix/widgets/app_offline_banner.dart';

final Logger _mainRouterLogger = Logger();

/// Shell principal post-login: bottom nav multi-rol y cuerpo según nivel.
class MainRouter extends StatefulWidget {
  const MainRouter({super.key});

  @override
  MainRouterState createState() => MainRouterState();
}

class MainRouterState extends State<MainRouter> {
  int _selectedLevel = 0;
  int _bottomNavIndex = 0;
  List<int> _allowedLevels = [];
  String? _lastRole;
  String? _positionLoadedForRole;
  StreamSubscription<NotificationItem>? _notificationSubscription;
  Future<Map<String, dynamic>>? _userDetailsFuture;
  bool _storefrontQrConsumeScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadLastPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _userDetailsFuture = context.read<UserProvider>().getUserDetails();
      final notifService = context.read<NotificationService>();
      notifService.loadCachedNotifications();
      Future.delayed(
          const Duration(seconds: 1), () => notifService.loadInitialData());

      _notificationSubscription = notifService.newNotificationStream.listen((n) {
        if (mounted) {
          _showGlobalNotification(n);
        }
      });

      if (!kIsWeb) {
        FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
          if (message != null && mounted) {
            navigateFromRemoteMessageData(message.data);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _showGlobalNotification(NotificationItem notification) {
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? AppColors.slateBorder : AppColors.white,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: AppColors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppColors.white : AppColors.stitchTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedGray : AppColors.textMutedGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VER',
          textColor: AppColors.blue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    try {
      await ProfileService().getMyProfile();
      if (mounted) setState(() {});
    } catch (e) {
      _mainRouterLogger.e('Error obteniendo el perfil: $e');
    }
  }

  Future<void> _consumePendingStorefrontQr() async {
    final id = await StorefrontQrPending.consume();
    if (!mounted || id == null) return;
    try {
      final restaurant = await RestaurantService().fetchRestaurantDetails(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RestaurantDetailsPage.fromRestaurant(restaurant),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el restaurante: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _loadLastPosition() async {
    if (!mounted) return;
    setState(() {
      _bottomNavIndex = 0;
      _mainRouterLogger.i('Loaded last position - bottomNavIndex: 0 (sin rol aún)');
    });
  }

  Future<void> _loadPositionForRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final key = bottomNavStorageKey(role);
    final value = prefs.getInt(key) ?? 0;
    if (!mounted) return;
    setState(() {
      _bottomNavIndex = value;
      _positionLoadedForRole = role;
      _mainRouterLogger.i('Loaded last position for $role - bottomNavIndex: $value');
    });
  }

  Future<void> _saveLastPosition([int? index, String? role]) async {
    final valueToSave = index ?? _bottomNavIndex;
    final r = role ?? Provider.of<UserProvider>(context, listen: false).userRole;
    final key = bottomNavStorageKey(r);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, valueToSave);
    if (!mounted) return;
    _mainRouterLogger.i('Saved last position for ${r.isEmpty ? 'users' : r} - bottomNavIndex: $valueToSave');
  }

  String _labelForLevel(int level) {
    switch (level) {
      case 0:
        return 'Comprador';
      case 1:
        return 'Comercio';
      case 2:
        return 'Delivery Rider';
      case 3:
        return 'Delivery Company';
      case 4:
        return 'Admin';
      default:
        return 'Desconocido';
    }
  }

  IconData _iconForLevel(int level) {
    switch (level) {
      case 0:
        return Icons.shopping_bag;
      case 1:
        return Icons.storefront;
      case 2:
        return Icons.delivery_dining;
      case 3:
        return Icons.local_shipping;
      case 4:
        return Icons.admin_panel_settings;
      default:
        return Icons.help_outline;
    }
  }

  void _showLevelSelector() {
    if (_allowedLevels.length <= 1) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cambiar modo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ..._allowedLevels.map((level) {
                final selected = level == _selectedLevel;
                return ListTile(
                  leading: Icon(
                    _iconForLevel(level),
                    color: selected ? stitchPrimary : stitchSlate400,
                  ),
                  title: Text(_labelForLevel(level)),
                  trailing: selected
                      ? const Icon(Icons.check, color: stitchPrimary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLevel = level;
                      _bottomNavIndex = 0;
                      _saveLastPosition(0, _lastRole ?? 'users');
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems(int level, String role, [int cartItemCount = 0]) {
    List<BottomNavigationBarItem> items = [];

    switch (level) {
      case 0:
        final cartIcon = cartItemCount > 0
            ? Badge(
                label: Text('${cartItemCount > 99 ? '99+' : cartItemCount}'),
                child: const Icon(Icons.shopping_cart),
              )
            : const Icon(Icons.shopping_cart);
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: cartIcon,
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Mis Órdenes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Restaurantes',
          ),
        ];
        break;
      case 1:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Órdenes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reportes',
          ),
        ];
        break;
      case 2:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Entregas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Rutas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ganancias',
          ),
        ];
        break;
      case 3:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Agentes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Órdenes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
        ];
        break;
      case 4:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Usuarios',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Órdenes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ];
        break;
      default:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ayuda',
          ),
        ];
    }

    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Configuración',
      ),
    );

    return items;
  }

  void _onBottomNavTapped(int index, int itemCount) {
    _mainRouterLogger.i('Bottom navigation tapped: $index, Total items: $itemCount');

    if (index == itemCount - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage2()),
      );
    } else {
      setState(() {
        _bottomNavIndex = index;
        _mainRouterLogger.i('Bottom nav index changed to: $_bottomNavIndex');
        _saveLastPosition(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final rawRole = userProvider.userRole;
    final role = rawRole.isEmpty ? 'users' : rawRole;

    if (role != 'users') {
      _storefrontQrConsumeScheduled = false;
    }

    if (rawRole.isNotEmpty && _lastRole != role) {
      final wasUnset = _lastRole?.isEmpty ?? true;
      _lastRole = role;
      _positionLoadedForRole = null;
      _allowedLevels = levelsForRole(role);
      _selectedLevel = defaultLevelForRole(role);
      _userDetailsFuture = userProvider.getUserDetails();
      if (!wasUnset) {
        _bottomNavIndex = 0;
        _saveLastPosition(0, role);
      }
      _loadPositionForRole(role);
    } else if (rawRole.isNotEmpty && _positionLoadedForRole != role) {
      _loadPositionForRole(role);
    } else if (_allowedLevels.isEmpty) {
      _allowedLevels = levelsForRole(role);
      if (!_allowedLevels.contains(_selectedLevel)) {
        _selectedLevel = defaultLevelForRole(role);
        _bottomNavIndex = 0;
        _saveLastPosition(0, role);
      }
    }

    final isBuyerLevel = _selectedLevel == 0;

    return Scaffold(
      appBar: isBuyerLevel
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ZONI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.stitchTextDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'X',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: stitchPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: false,
              actions: [
                if (_allowedLevels.length > 1)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Cambiar modo',
                    onPressed: _showLevelSelector,
                  ),
                Consumer<NotificationService>(
                  builder: (context, notificationService, child) {
                    return IconButton(
                      icon: Badge(
                        label: Text('${notificationService.unreadCount}'),
                        isLabelVisible: notificationService.unreadCount > 0,
                        child: Icon(
                          Icons.notifications_none,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : AppColors.stitchTextDark,
                        ),
                      ),
                      tooltip: 'Notificaciones',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage()),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.gps_fixed,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : AppColors.stitchTextDark,
                  ),
                  tooltip: 'Ubicación / GPS',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationSearchPage()),
                    );
                  },
                ),
              ],
            ),
      body: AppOfflineBanner(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              if (snapshot.error is SessionRejectedByApiException) {
                return const Center(child: CircularProgressIndicator());
              }
              _mainRouterLogger.e('Error fetching user details: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              _mainRouterLogger.i('Role fetched: $role');

              _selectedLevel = defaultLevelForRole(role);

              if (_selectedLevel == 0) {
                final page = switch (_bottomNavIndex) {
                  0 => const ProductsPage(),
                  1 => const CartPage(),
                  2 => const OrdersPage(),
                  3 => const RestaurantsPage(),
                  _ => const ProductsPage(),
                };
                if (role == 'users' && !_storefrontQrConsumeScheduled) {
                  _storefrontQrConsumeScheduled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _consumePendingStorefrontQr();
                  });
                }
                return BuyerShell(child: page);
              }

              if (_selectedLevel == 1) {
                switch (_bottomNavIndex) {
                  case 0:
                    return const CommerceDashboardPage();
                  case 1:
                    return const CommerceOrdersPage();
                  case 2:
                    return const CommerceProductsPage();
                  case 3:
                    return const CommerceReportsPage();
                  default:
                    return const CommerceDashboardPage();
                }
              }

              if (_selectedLevel == 2) {
                switch (_bottomNavIndex) {
                  case 0:
                    return const DeliveryOrdersPage();
                  case 1:
                    return const DeliveryHistoryPage();
                  case 2:
                    return const DeliveryRoutesPage();
                  case 3:
                    return const DeliveryEarningsPage();
                  default:
                    return const DeliveryOrdersPage();
                }
              }

              if (_selectedLevel == 3) {
                switch (_bottomNavIndex) {
                  case 0:
                    return const DeliveryCompanyDashboardPage();
                  case 1:
                    return const DeliveryCompanyAgentsPage();
                  case 2:
                    return const DeliveryCompanyOrdersPage();
                  case 3:
                    return const DeliveryCompanyMapPage();
                  default:
                    return const DeliveryCompanyDashboardPage();
                }
              }

              if (_selectedLevel == 4) {
                switch (_bottomNavIndex) {
                  case 0:
                    return const AdminDashboardPage();
                  case 1:
                    return const AdminUsersPage();
                  case 2:
                    return const AdminOrdersPage();
                  case 3:
                    return const AdminAnalyticsPage();
                  default:
                    return const AdminDashboardPage();
                }
              }

              return const Center(
                child: Text('Rol no reconocido o página no encontrada'),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? stitchNavBg : stitchBgLight,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Consumer<CartService>(
          builder: (context, cartService, _) {
            final cartCount = _selectedLevel == 0
                ? cartService.items.fold<int>(0, (s, i) => s + i.quantity)
                : 0;
            return BottomNavigationBar(
              items: _getBottomNavItems(_selectedLevel, userProvider.userRole, cartCount),
              currentIndex: _bottomNavIndex,
              selectedItemColor: stitchNavActive,
              unselectedItemColor: stitchSlate400,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (index) {
                final c = context.read<CartService>().items.fold<int>(0, (s, i) => s + i.quantity);
                final items = _getBottomNavItems(
                  _selectedLevel,
                  userProvider.userRole,
                  _selectedLevel == 0 ? c : 0,
                );
                _onBottomNavTapped(index, items.length);
              },
            );
          },
        ),
      ),
    );
  }
}
