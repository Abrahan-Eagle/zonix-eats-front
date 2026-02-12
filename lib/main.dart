




import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:flutter/services.dart';

// import 'dart:io';
// import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix/features/screens/profile/profile_page.dart';
import 'package:zonix/features/screens/settings/settings_page_2.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';


import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';
import 'package:zonix/features/screens/orders/orders_page.dart';
import 'package:zonix/features/screens/restaurants/restaurants_page.dart';

import 'package:zonix/features/screens/cart/checkout_page.dart';

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
import 'package:zonix/features/screens/delivery/delivery_orders_page.dart';
import 'package:zonix/features/screens/delivery/delivery_history_page.dart';
import 'package:zonix/features/screens/delivery/delivery_routes_page.dart';
import 'package:zonix/features/screens/delivery/delivery_earnings_page.dart';
import 'package:zonix/features/screens/admin/admin_dashboard_page.dart';
import 'package:zonix/features/screens/admin/admin_users_page.dart';
import 'package:zonix/features/screens/admin/admin_security_page.dart';
import 'package:zonix/features/screens/admin/admin_analytics_page.dart';

import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_page.dart';
import 'package:zonix/features/screens/commerce/commerce_notifications_page.dart';
import 'package:zonix/features/screens/commerce/commerce_profile_page.dart';
import 'package:zonix/features/screens/onboarding/onboarding_provider.dart';

/*
 * ZONIX EATS - Aplicación Multi-Rol
 * 
 * Niveles de usuario (según roles):
 * 0 - Comprador (users): Productos, Carrito, Mis Órdenes, Restaurantes
 * 1 - Tiendas/Comercio (commerce): Dashboard, Inventario, Órdenes, Reportes
 * 2 - Delivery (delivery): Entregas, Historial, Rutas, Ganancias
 * 3 - Administrador (admin): Panel Admin, Usuarios, Seguridad, Sistema
 */

const FlutterSecureStorage _storage = FlutterSecureStorage();
final ApiService apiService = ApiService();

final String baseUrl =
    const bool.fromEnvironment('dart.vm.product')
        ? dotenv.env['API_URL_PROD']!
        : dotenv.env['API_URL_LOCAL']!;

// Configuración del logger
final logger = Logger();

//  class MyHttpOverrides extends HttpOverrides{
//   @override
//   HttpClient createHttpClient(SecurityContext? context){
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
//   }
// }

// void main() {
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
  final bool isIntegrationTest = const String.fromEnvironment('INTEGRATION_TEST', defaultValue: 'false') == 'true';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
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
      child: MyApp(isIntegrationTest: isIntegrationTest),
    ),
  );
}

void initialization() async {
  logger.i('Initializing...');
  await Future.delayed(const Duration(seconds: 3));
  FlutterNativeSplash.remove();
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
      title: 'ZONIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.blue,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.blue,
          secondary: AppColors.orange,
          error: AppColors.red,
          background: AppColors.white,
        ),
        cardColor: AppColors.grayLight,
        buttonTheme: ButtonThemeData(
          buttonColor: AppColors.orange,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.orange,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.purple,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: AppColors.purple,
          secondary: AppColors.orangeCoral,
          error: AppColors.red,
          background: AppColors.backgroundDark,
        ),
        cardColor: AppColors.grayDark,
        buttonTheme: ButtonThemeData(
          buttonColor: AppColors.orangeCoral,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.orangeCoral,
        ),
      ),
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
        '/commerce/inventory': (context) => const CommerceProductsPage(),
        '/commerce/products': (context) => const CommerceProductsPage(),
        '/commerce/orders': (context) => const CommerceOrdersPage(),
        '/commerce/profile': (context) => CommerceProfilePage(),
        '/commerce/chat': (context) => const CommerceChatPage(),
        '/commerce/notifications': (context) => const CommerceNotificationsPage(),
        '/commerce/reports': (context) => const CommerceReportsPage(),
        '/commerce/products/create': (context) => const CommerceProductFormPage(),
      },
      onGenerateRoute: (settings) {
        final path = settings.name ?? '';
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
  dynamic _profile;
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
        // Perfil del usuario autenticado (GET /api/profile), no requiere user id ni profile id
        _profile = await ProfileService().getMyProfile();
        if (mounted) setState(() {});
      } catch (e) {
        logger.e('Error obteniendo el perfil: $e');
      }
    }

  Future<void> _loadLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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
                    color: selected ? Colors.blueAccent : Colors.grey,
                  ),
                  title: Text(_labelForLevel(level)),
                  trailing: selected
                      ? const Icon(Icons.check, color: Colors.blueAccent)
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
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Función para obtener los items del BottomNavigationBar
  List<BottomNavigationBarItem> _getBottomNavItems(int level, String role) {
    List<BottomNavigationBarItem> items = [];

    switch (level) {
      case 0: // Comprador
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Productos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 4.0,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'ZONI',
                style: TextStyle(
                  fontFamily: 'system-ui',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  fontFamily: 'system-ui',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.blueAccent[700]
                          : Colors.orange,
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
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return GestureDetector(
                onTap: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(200, 80, 0, 0),
                    items: [
                      PopupMenuItem(
                        child: const Text('Mi QR'),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage1(),
                              ),
                            ),
                      ),
                      PopupMenuItem(
                        child: const Text('Configuración'),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage2(),
                              ),
                            ),
                      ),
                      PopupMenuItem(
                        child: const Text('Cerrar sesión'),
                        onTap: () async {
                          await userProvider.logout();
                          // await _storage.deleteAll();
                          if (!mounted) return;
                        
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const SignInScreen()), // Redirige al login
                            (Route<dynamic> route) => false, // Elimina todas las rutas previas
                          );

                       },
                      ),
                    ],
                  );
                },

                child: FutureBuilder<String?>(
                  future: _storage.read(key: 'userPhotoUrl'),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<String?> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(radius: 20);
                    } else if (snapshot.hasError ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        // child: CircleAvatar(
                        //   radius: 20,
                        //   child: ClipOval(
                        //     child: Image.network(
                        //       snapshot.data!,
                        //       fit: BoxFit.cover,
                        //     ),
                        //   ),
                        // ),
                        child: CircleAvatar(
                            radius: 20,
                            backgroundImage: _getProfileImage(
                                    _profile?.photo, // Foto del perfil del usuario (desde el backend)
                                     snapshot.data!, // Foto de Google (si está disponible)
                                  ),
                            child: (_profile?.photo == null &&  snapshot.data == null)
                                ? const Icon(Icons.person, color: Colors.white) // Ícono predeterminado si no hay foto
                                : null,
                          ),

                     );
                    }
                  },
                ),
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

                // Nivel 0: Comprador
                if (_selectedLevel == 0) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return const ProductsPage();
                    case 1:
                      return const CartPage();
                    case 2:
                      return const OrdersPage();
                    case 3:
                      return const RestaurantsPage();
                    default:
                      return const ProductsPage();
                  }
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
                      return DeliveryOrdersPage(); // Entregas
                    case 1:
                      return const DeliveryHistoryPage(); // Historial
                    case 2:
                      return const DeliveryRoutesPage(); // Rutas
                    case 3:
                      return const DeliveryEarningsPage(); // Ganancias
                    default:
                      return DeliveryOrdersPage();
                  }
                }

                // Nivel 3: Delivery Company
                if (_selectedLevel == 3) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return DeliveryOrdersPage(); // Entregas (empresa)
                    case 1:
                      return const DeliveryHistoryPage(); // Historial
                    case 2:
                      return const DeliveryRoutesPage(); // Rutas
                    case 3:
                      return const DeliveryEarningsPage(); // Ganancias
                    default:
                      return DeliveryOrdersPage();
                  }
                }

                // Nivel 4: Administrador
                if (_selectedLevel == 4) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return AdminDashboardPage(); // Panel Admin
                    case 1:
                      return const AdminUsersPage(); // Usuarios
                    case 2:
                      return const AdminSecurityPage(); // Seguridad
                    case 3:
                      return const AdminAnalyticsPage(); // Sistema/Analíticas
                    default:
                      return AdminDashboardPage();
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
      bottomNavigationBar: BottomNavigationBar(
        items: _getBottomNavItems(_selectedLevel, userProvider.userRole),
        currentIndex: _bottomNavIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Obtener el itemCount llamando a _getBottomNavItems antes de la navegación
          List<BottomNavigationBarItem> items = _getBottomNavItems(
            _selectedLevel,
            userProvider.userRole,
          );
          int itemCount = items.length;

          // Llamar a la función _onBottomNavTapped con el index y el itemCount
          _onBottomNavTapped(index, itemCount);
        },
      ),
    );
  }
}

ImageProvider<Object> _getProfileImage(String? profilePhoto, String? googlePhotoUrl) {
  if (profilePhoto != null && profilePhoto.isNotEmpty) {
    // Detectar URLs de placeholder y evitarlas
    if (profilePhoto.contains('via.placeholder.com') || 
        profilePhoto.contains('placeholder.com') ||
        profilePhoto.contains('placehold.it')) {
      logger.w('Detectada URL de placeholder en perfil, usando imagen local: $profilePhoto');
      return const AssetImage('assets/default_avatar.png');
    }
    
    logger.i('Usando foto del perfil: $profilePhoto');
    return NetworkImage(profilePhoto); // Imagen del perfil del usuario
  }
  if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
    logger.i('Usando foto de Google: $googlePhotoUrl');
    return NetworkImage(googlePhotoUrl); // Imagen de Google
  }
  logger.w('Usando imagen predeterminada');
  return const AssetImage('assets/default_avatar.png'); // Imagen predeterminada
}
