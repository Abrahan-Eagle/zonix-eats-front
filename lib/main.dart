




import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';


import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';
import 'package:zonix/features/screens/orders/orders_page.dart';
import 'package:zonix/features/screens/restaurants/restaurants_page.dart';

import 'package:zonix/features/screens/cart/checkout_page.dart';

import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/screens/orders/commerce_orders_page.dart';
import 'package:zonix/features/services/commerce_service.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/services/admin_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/services/chat_service.dart';
import 'package:zonix/features/services/analytics_service.dart';
import 'package:zonix/features/screens/commerce/commerce_dashboard_page.dart';
import 'package:zonix/features/screens/commerce/commerce_inventory_page.dart';
import 'package:zonix/features/screens/commerce/commerce_reports_page.dart';
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
import 'package:zonix/features/screens/commerce/commerce_notifications_page.dart';
import 'package:zonix/features/screens/commerce/commerce_profile_page.dart';

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
          if (userProvider.isAuthenticated) {
            return const MainRouter();
          } else {
            return const SignInScreen();
          }
        },
      ),
      routes: {
        '/commerce/inventory': (context) => const CommerceInventoryPage(),
        '/commerce/orders': (context) => const CommerceOrdersPage(),
        '/commerce/profile': (context) => CommerceProfilePage(),
        '/commerce/notifications': (context) => const CommerceNotificationsPage(),
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastPosition();
  }


   Future<void> _loadProfile() async {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Obtén los detalles del usuario y verifica su contenido
        final userDetails = await userProvider.getUserDetails();
       

        // Extrae y valida el ID del usuario
        final id = userDetails['userId'];
        if (id == null || id is! int) {
          throw Exception('El ID del usuario es inválido: $id');
        }
        // Obtén el perfil usando el ID del usuario
        _profile = await ProfileService().getProfileById(id);
       
        setState(() {});
      } catch (e) {
        logger.e('Error obteniendo el ID del usuario: $e');
      }
    }

  Future<void> _loadLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      int savedLevel = prefs.getInt('selectedLevel') ?? 0;
      // Validar que el nivel guardado sea válido (0-3)
      // Si es 4 o 5 (niveles eliminados), convertir a 3 (admin)
      if (savedLevel == 4 || savedLevel == 5) {
        _selectedLevel = 3; // Admin
      } else if (savedLevel > 3) {
        _selectedLevel = 0; // Default a comprador
      } else {
        _selectedLevel = savedLevel;
      }
      _bottomNavIndex = prefs.getInt('bottomNavIndex') ?? 0;
      logger.i(
        'Loaded last position - selectedLevel: $_selectedLevel, bottomNavIndex: $_bottomNavIndex',
      );
    });
  }

  Future<void> _saveLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedLevel', _selectedLevel);
    await prefs.setInt('bottomNavIndex', _bottomNavIndex);
    logger.i(
      'Saved last position - selectedLevel: $_selectedLevel, bottomNavIndex: $_bottomNavIndex',
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
      case 2: // Delivery
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
      case 3: // Administrador
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

  // Dentro de tu widget donde tienes el BottomNavigationBar

  void _onLevelSelected(int level) {
    setState(() {
      _selectedLevel = level;
      _bottomNavIndex = 0;
      _saveLastPosition();
    });
  }

  Widget _createLevelButton(int level, IconData icon, String tooltip) {
    return FloatingActionButton.small(
      heroTag: 'level$level',
      backgroundColor:
          _selectedLevel == level
              ? Colors.blueAccent[700]
              : Colors.blueAccent[50],
      child: Icon(
        icon,
        color: _selectedLevel == level ? Colors.white : Colors.black,
      ),
      onPressed: () => _onLevelSelected(level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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
                      return const CommerceInventoryPage(); // Productos
                    case 3:
                      return const CommerceReportsPage(); // Reportes
                    default:
                      return const CommerceDashboardPage();
                  }
                }

                // Nivel 2: Delivery
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

                // Nivel 3: Administrador
                if (_selectedLevel == 3) {
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 70,
        type: ExpandableFabType.up,
        children: [
          _createLevelButton(0, Icons.shopping_bag, 'Comprador'),
          _createLevelButton(1, Icons.storefront, 'Tiendas'),
          _createLevelButton(2, Icons.delivery_dining, 'Delivery'),
          _createLevelButton(3, Icons.admin_panel_settings, 'Administrador'),
        ],
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
