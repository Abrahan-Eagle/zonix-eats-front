




import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';
import 'package:flutter/services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix/features/screens/settings/settings_page_2.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';


import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';
import 'package:zonix/features/screens/orders/orders_page.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/restaurants/restaurants_page.dart';


import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/commerce_service.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/services/admin_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/services/chat_service.dart';
import 'package:zonix/features/services/analytics_service.dart';
import 'package:zonix/features/services/commerce_analytics_service.dart';
import 'package:zonix/features/screens/commerce/commerce_dashboard_page.dart';
import 'package:zonix/features/screens/commerce/commerce_orders_page.dart';
import 'package:zonix/features/screens/commerce/commerce_order_detail_page.dart';
import 'package:zonix/features/screens/commerce/commerce_products_page.dart';
import 'package:zonix/features/screens/commerce/commerce_product_form_page.dart';
import 'package:zonix/features/screens/commerce/commerce_reports_page.dart';
import 'package:zonix/models/commerce_product.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/delivery/delivery_orders_page.dart';
import 'package:zonix/features/screens/delivery/delivery_history_page.dart';
import 'package:zonix/features/screens/delivery/delivery_routes_page.dart';
import 'package:zonix/features/screens/delivery/delivery_earnings_page.dart';
import 'package:zonix/features/screens/admin/admin_dashboard_page.dart';
import 'package:zonix/features/screens/admin/admin_users_page.dart';
import 'package:zonix/features/screens/admin/admin_security_page.dart';
import 'package:zonix/features/screens/admin/admin_analytics_page.dart';

import 'package:zonix/features/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_page.dart';
import 'package:zonix/features/screens/commerce/commerce_notifications_page.dart';
import 'package:zonix/features/screens/commerce/commerce_profile_page.dart';
import 'package:zonix/features/screens/onboarding/onboarding_provider.dart';
import 'package:zonix/features/screens/location/location_search_page.dart';
import 'package:zonix/features/widgets/buyer_shell.dart';

/*
 * ZONIX EATS - Aplicación Multi-Rol
 * 
 * Niveles de usuario (según roles):
 * 0 - Comprador (users): Productos, Carrito, Mis Órdenes, Restaurantes
 * 1 - Tiendas/Comercio (commerce): Dashboard, Inventario, Órdenes, Reportes
 * 2 - Delivery (delivery): Entregas, Historial, Rutas, Ganancias
 * 3 - Administrador (admin): Panel Admin, Usuarios, Seguridad, Sistema
 */

final ApiService apiService = ApiService();

final String baseUrl =
    const bool.fromEnvironment('dart.vm.product')
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

// Configuración del logger
final logger = Logger();

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  initialization();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load();

  // Bypass de login para tests de integración
  const bool isIntegrationTest = String.fromEnvironment('INTEGRATION_TEST', defaultValue: 'false') == 'true';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => SearchRadiusProvider()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => CommerceService()),
        ChangeNotifierProvider(create: (_) => DeliveryService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => CommerceAnalyticsService()),
        // PusherService se maneja como singleton interno, no necesitamos Provider aquí.
      ],
      child: const MyApp(isIntegrationTest: isIntegrationTest),
    ),
  );
}

void initialization() async {
  logger.i('Initializing...');
  await Future.delayed(const Duration(seconds: 3));
  FlutterNativeSplash.remove();
}

// Paleta Stitch (template)
const Color _stitchPrimary = Color(0xFF3399FF);
const Color _stitchBgLight = Color(0xFFF5F7F8);
const Color _stitchBgDark = Color(0xFF0F1923);
const Color _stitchSurfaceDark = Color(0xFF1A2733);
const Color _stitchCardCream = Color(0xFFF9F0E0);
const Color _stitchNavBg = Color(0xFF1A2E46);
const Color _stitchNavActive = Color(0xFF3299FF);
const Color _stitchSlate400 = Color(0xFF94A3B8);

ThemeData _buildStitchLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    primaryColor: _stitchPrimary,
    scaffoldBackgroundColor: _stitchBgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: _stitchPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.light(
      primary: _stitchPrimary,
      secondary: AppColors.orange,
      error: AppColors.red,
      surface: _stitchBgLight,
      onPrimary: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    cardColor: _stitchCardCream,
    cardTheme: CardThemeData(
      color: _stitchCardCream,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _stitchPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _stitchPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _stitchBgLight,
      selectedItemColor: _stitchNavActive,
      unselectedItemColor: _stitchSlate400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData _buildStitchDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    primaryColor: _stitchPrimary,
    scaffoldBackgroundColor: _stitchBgDark,
    appBarTheme: AppBarTheme(
      backgroundColor: _stitchBgDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: _stitchPrimary,
      secondary: AppColors.orangeCoral,
      error: AppColors.red,
      surface: _stitchSurfaceDark,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    cardColor: _stitchSurfaceDark,
    cardTheme: CardThemeData(
      color: _stitchSurfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _stitchPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _stitchPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _stitchSurfaceDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _stitchNavBg,
      selectedItemColor: _stitchNavActive,
      unselectedItemColor: _stitchSlate400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isIntegrationTest;
  const MyApp({super.key, this.isIntegrationTest = false});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (isIntegrationTest) {
      // Forzar autenticación como comercio
      userProvider.setAuthenticatedForTest(role: 'commerce');
    } else {
      userProvider.checkAuthentication();
    }

    return MaterialApp(
      title: 'Zonix Eats',
      debugShowCheckedModeBanner: false,
      theme: _buildStitchLightTheme(),
      darkTheme: _buildStitchDarkTheme(),
      themeMode: ThemeMode.system,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          logger.i('isAuthenticated: ${userProvider.isAuthenticated}');
          if (!userProvider.isAuthenticated) {
            return const SignInScreen();
          }
          if (!userProvider.completedOnboarding) {
            return const OnboardingScreen();
          }
          return const MainRouter();
        },
      ),
      routes: {
        '/restaurants': (context) => const RestaurantsPage(),
        '/commerce/inventory': (context) => const CommerceProductsPage(),
        '/commerce/products': (context) => const CommerceProductsPage(),
        '/commerce/orders': (context) => const CommerceOrdersPage(),
        '/commerce/profile': (context) => const CommerceProfilePage(),
        '/commerce/chat': (context) => const CommerceChatPage(),
        '/commerce/notifications': (context) => const CommerceNotificationsPage(),
        '/commerce/reports': (context) => const CommerceReportsPage(),
        '/commerce/products/create': (context) => const CommerceProductFormPage(),
      },
      onGenerateRoute: (settings) {
        final path = settings.name ?? '';
        if (path == '/order-details') {
          final order = settings.arguments is Order ? settings.arguments as Order : null;
          if (order != null) {
            return MaterialPageRoute(
              builder: (context) => OrderDetailPage(orderId: order.id, order: order),
            );
          }
        }
        final orderMatch = RegExp(r'^/commerce/order/(\d+)$').firstMatch(path);
        if (orderMatch != null) {
          final orderId = int.parse(orderMatch.group(1)!);
          return MaterialPageRoute(
            builder: (context) => CommerceOrderDetailPage(orderId: orderId),
          );
        }
        final productMatch = RegExp(r'^/commerce/products/(\d+)$').firstMatch(path);
        if (productMatch != null) {
          final product = settings.arguments is CommerceProduct
              ? settings.arguments as CommerceProduct
              : null;
          return MaterialPageRoute(
            builder: (context) => CommerceProductFormPage(product: product),
          );
        }
        return null;
      },
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastPosition();
  }


   Future<void> _loadProfile() async {
      try {
        await ProfileService().getMyProfile();
        if (mounted) setState(() {});
      } catch (e) {
        logger.e('Error obteniendo el perfil: $e');
      }
    }

  Future<void> _loadLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bottomNavIndex = prefs.getInt('bottomNavIndex') ?? 0;
      logger.i(
        'Loaded last position - bottomNavIndex: $_bottomNavIndex',
      );
    });
  }

  Future<void> _saveLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bottomNavIndex', _bottomNavIndex);
    if (!mounted) return;
    logger.i(
      'Saved last position - bottomNavIndex: $_bottomNavIndex',
    );
  }

  int _defaultLevelForRole(String role) {
    switch (role) {
      case 'commerce':
        return 1;
      case 'delivery_agent':
      case 'delivery':
        return 2;
      case 'delivery_company':
        return 3;
      case 'admin':
        return 4;
      case 'users':
      default:
        return 0;
    }
  }

  List<int> _levelsForRole(String role) {
    // Mapeo de niveles según rol:
    // 0: Comprador
    // 1: Comercio
    // 2: Delivery Rider (motorizado / conductor)
    // 3: Delivery Company
    // 4: Admin
    switch (role) {
      case 'commerce':
        // Comercio SOLO usa su propio nivel (no debe ver comprador)
        return [1];
      case 'delivery_agent':
      case 'delivery':
        // Riders: SOLO su propio nivel (2), no ven comprador
        return [2];
      case 'delivery_company':
        // Empresas de delivery: solo su propio nivel (3)
        return [3];
      case 'admin':
        // Admin SOLO usa su nivel (4)
        return [4];
      case 'users':
      default:
        // Comprador normal
        return [0];
    }
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
        return Icons.local_shipping; // Delivery Company
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
                    color: selected ? _stitchPrimary : _stitchSlate400,
                  ),
                  title: Text(_labelForLevel(level)),
                  trailing: selected
                      ? const Icon(Icons.check, color: _stitchPrimary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLevel = level;
                      _bottomNavIndex = 0;
                      _saveLastPosition();
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

  // Función para obtener los items del BottomNavigationBar
  List<BottomNavigationBarItem> _getBottomNavItems(int level, String role, [int cartItemCount = 0]) {
    List<BottomNavigationBarItem> items = [];

    switch (level) {
      case 0: // Comprador (template: badge en Carrito)
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
      case 1: // Tiendas/Comercio
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
      case 2: // Delivery Rider
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
      case 3: // Delivery Company
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
      case 4: // Administrador
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Panel Admin',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Usuarios',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Seguridad',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_system_daydream),
            label: 'Sistema',
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

    // Agregar el item de configuración siempre
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Configuración',
      ),
    );


    // Devolver los items y el contador
    return items;
  }

  // Función para manejar el tap en el BottomNavigationBar
  void _onBottomNavTapped(int index, int itemCount) {
    logger.i('Bottom navigation tapped: $index, Total items: $itemCount');

    // Verifica si el índice seleccionado es el último item
    if (index == itemCount - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage2()),
      );
    } else {
      setState(() {
        _bottomNavIndex = index; // Actualiza el índice seleccionado
        logger.i('Bottom nav index changed to: $_bottomNavIndex');
        _saveLastPosition();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Calcular niveles permitidos según el rol del usuario
    var role = userProvider.userRole;
    if (role.isEmpty) {
      role = 'users';
    }

    // Si el rol cambió (ej. después de login), forzamos el nivel por defecto de ese rol
    if (_lastRole != role) {
      _lastRole = role;
      _allowedLevels = _levelsForRole(role);
      _selectedLevel = _defaultLevelForRole(role);
      _bottomNavIndex = 0;
      _saveLastPosition();
    } else if (_allowedLevels.isEmpty) {
      // Primera vez que se calculan los niveles permitidos
      _allowedLevels = _levelsForRole(role);
      if (!_allowedLevels.contains(_selectedLevel)) {
        _selectedLevel = _defaultLevelForRole(role);
        _bottomNavIndex = 0;
        _saveLastPosition();
      }
    }

    final isBuyerLevel = _selectedLevel == 0;

    return Scaffold(
      appBar: isBuyerLevel ? null : AppBar(
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
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: 'X',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _stitchPrimary,
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
          IconButton(
            icon: Icon(
              Icons.gps_fixed,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : const Color(0xFF0F172A),
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
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return FutureBuilder<Map<String, dynamic>>(
            future: userProvider.getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                logger.e('Error fetching user details: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              } // Dentro del FutureBuilder
              else {
                final role = userProvider.userRole;
                logger.i('Role fetched: $role');

                // Forzar SIEMPRE el nivel según el rol para evitar que quede en 0 por defecto
                _selectedLevel = _defaultLevelForRole(role);

                // Nivel 0: Comprador - BuyerShell (header Delivering to + search) + nav original
                if (_selectedLevel == 0) {
                  final page = switch (_bottomNavIndex) {
                    0 => const ProductsPage(),
                    1 => const CartPage(),
                    2 => const OrdersPage(),
                    3 => const RestaurantsPage(),
                    _ => const ProductsPage(),
                  };
                  return BuyerShell(child: page);
                }

                // Nivel 1: Tiendas/Comercio
                if (_selectedLevel == 1) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return const CommerceDashboardPage(); // Dashboard
                    case 1:
                      return const CommerceOrdersPage(); // Órdenes
                    case 2:
                      return const CommerceProductsPage(); // Productos
                    case 3:
                      return const CommerceReportsPage(); // Reportes
                    default:
                      return const CommerceDashboardPage();
                  }
                }

                // Nivel 2: Delivery Rider (motorizado / conductor)
                if (_selectedLevel == 2) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return const DeliveryOrdersPage(); // Entregas
                    case 1:
                      return const DeliveryHistoryPage(); // Historial
                    case 2:
                      return const DeliveryRoutesPage(); // Rutas
                    case 3:
                      return const DeliveryEarningsPage(); // Ganancias
                    default:
                      return const DeliveryOrdersPage();
                  }
                }

                // Nivel 3: Delivery Company
                if (_selectedLevel == 3) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return const DeliveryOrdersPage(); // Entregas (empresa)
                    case 1:
                      return const DeliveryHistoryPage(); // Historial
                    case 2:
                      return const DeliveryRoutesPage(); // Rutas
                    case 3:
                      return const DeliveryEarningsPage(); // Ganancias
                    default:
                      return const DeliveryOrdersPage();
                  }
                }

                // Nivel 4: Administrador
                if (_selectedLevel == 4) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return const AdminDashboardPage(); // Panel Admin
                    case 1:
                      return const AdminUsersPage(); // Usuarios
                    case 2:
                      return const AdminSecurityPage(); // Seguridad
                    case 3:
                      return const AdminAnalyticsPage(); // Sistema/Analíticas
                    default:
                      return const AdminDashboardPage();
                  }
                }

                // Si no se cumplen ninguna de las condiciones anteriores, puedes manejar un caso por defecto.
                return const Center(
                  child: Text('Rol no reconocido o página no encontrada'),
                );
              }
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? _stitchNavBg
              : _stitchBgLight,
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
          selectedItemColor: _stitchNavActive,
          unselectedItemColor: _stitchSlate400,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            final cartCount = context.read<CartService>().items.fold<int>(0, (s, i) => s + i.quantity);
            List<BottomNavigationBarItem> items = _getBottomNavItems(
              _selectedLevel,
              userProvider.userRole,
              _selectedLevel == 0 ? cartCount : 0,
            );
            int itemCount = items.length;
            _onBottomNavTapped(index, itemCount);
          },
        );
          },
        ),
      ),
    );
  }
}
