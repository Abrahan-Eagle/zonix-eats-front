// import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:zonix/features/services/auth/api_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:provider/provider.dart';
// import 'package:zonix/features/utils/user_provider.dart';
// import 'package:flutter/services.dart';
// import 'package:zonix/features/screens/profile/profile_page.dart';
// import 'package:zonix/features/screens/settings/settings_page_2.dart';
// import 'package:zonix/features/screens/auth/sign_in_screen.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
// import 'package:zonix/features/screens/products/products_page.dart';
// import 'package:zonix/features/screens/cart/cart_page.dart';
// import 'package:zonix/features/screens/orders/orders_page.dart';
// import 'package:zonix/features/screens/restaurants/restaurants_page.dart';
// import 'package:zonix/features/services/cart_service.dart';
// import 'package:zonix/features/services/order_service.dart';
// import 'package:zonix/features/screens/orders/commerce_orders_page.dart';

// const FlutterSecureStorage _storage = FlutterSecureStorage();
// final ApiService apiService = ApiService();

// final String baseUrl =
//     const bool.fromEnvironment('dart.vm.product')
//         ? dotenv.env['API_URL_PROD']!
//         : dotenv.env['API_URL_LOCAL']!;

// // Configuración del logger
// final logger = Logger();

// //  class MyHttpOverrides extends HttpOverrides{
// //   @override
// //   HttpClient createHttpClient(SecurityContext? context){
// //     return super.createHttpClient(context)
// //       ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
// //   }
// // }

// // void main() {
// Future<void> main() async {
//   WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//   initialization();

//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   await dotenv.load();
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//         ChangeNotifierProvider(create: (_) => CartService()),
//         ChangeNotifierProvider(create: (_) => OrderService()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// void initialization() async {
//   logger.i('Initializing...');
//   await Future.delayed(const Duration(seconds: 3));
//   FlutterNativeSplash.remove();
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Provider.of<UserProvider>(context, listen: false).checkAuthentication();

//     return MaterialApp(
//       title: 'ZONIX',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       themeMode: ThemeMode.system,
//       home: Consumer<UserProvider>(
//         builder: (context, userProvider, child) {
//           logger.i('isAuthenticated:  [32m [1m [4m [7m${userProvider.isAuthenticated} [0m');
//           if (userProvider.isAuthenticated) {
//             if (userProvider.userRole == 'users') {
//               return const MainRouter();
//             } else if (userProvider.userRole == 'commerce') {
//               return const CommerceOrdersPage();
//             } else {
//               // Rol desconocido, fallback
//               return const MainRouter();
//             }
//           } else {
//             return const SignInScreen();
//           }
//         },
//       ),
//     );
//   }
// }

// class MainRouter extends StatefulWidget {
//   const MainRouter({super.key});

//   @override
//   MainRouterState createState() => MainRouterState();
// }

// class MainRouterState extends State<MainRouter> {
//   int _bottomNavIndex = 0;
//   dynamic _profile;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//     _loadLastPosition();
//   }

//   Future<void> _loadProfile() async {
//     try {
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final userDetails = await userProvider.getUserDetails();
//       final id = userDetails['userId'];
//       if (id == null || id is! int) {
//         throw Exception('El ID del usuario es inválido: $id');
//       }
//       _profile = await ProfileService().getProfileById(id);
//       setState(() {});
//     } catch (e) {
//       logger.e('Error obteniendo el ID del usuario: $e');
//     }
//   }

//   Future<void> _loadLastPosition() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _bottomNavIndex = prefs.getInt('bottomNavIndex') ?? 0;
//       logger.i('Loaded last position - bottomNavIndex: $_bottomNavIndex');
//     });
//   }

//   Future<void> _saveLastPosition() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('bottomNavIndex', _bottomNavIndex);
//     logger.i('Saved last position - bottomNavIndex: $_bottomNavIndex');
//   }

//   List<BottomNavigationBarItem> _getBottomNavItems() {
//     return [
//       const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Productos'),
//       const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
//       const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Órdenes'),
//       const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurantes'),
//       const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
//     ];
//   }

//   void _onBottomNavTapped(int index) {
//     logger.i('Bottom navigation tapped: $index');
//     if (index == 4) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const SettingsPage2()),
//       );
//     } else {
//       setState(() {
//         _bottomNavIndex = index;
//         _saveLastPosition();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         elevation: 4.0,
//         title: RichText(
//           text: TextSpan(
//             children: [
//               TextSpan(
//                 text: 'ZONI',
//                 style: TextStyle(
//                   fontFamily: 'system-ui',
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//               TextSpan(
//                 text: 'X',
//                 style: TextStyle(
//                   fontFamily: 'system-ui',
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent[700] : Colors.orange,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         centerTitle: false,
//         actions: [
//           Consumer<UserProvider>(
//             builder: (context, userProvider, child) {
//               return GestureDetector(
//                 onTap: () {
//                   showMenu(
//                     context: context,
//                     position: const RelativeRect.fromLTRB(200, 80, 0, 0),
//                     items: [
//                       PopupMenuItem(
//                         child: const Text('Mi QR'),
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const ProfilePage1(),
//                           ),
//                         ),
//                       ),
//                       PopupMenuItem(
//                         child: const Text('Configuración'),
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const SettingsPage2(),
//                           ),
//                         ),
//                       ),
//                       PopupMenuItem(
//                         child: const Text('Cerrar sesión'),
//                         onTap: () async {
//                           await userProvider.logout();
//                           if (!mounted) return;
//                           Navigator.of(context).pushAndRemoveUntil(
//                             MaterialPageRoute(builder: (context) => const SignInScreen()),
//                             (Route<dynamic> route) => false,
//                           );
//                         },
//                       ),
//                     ],
//                   );
//                 },
//                 child: FutureBuilder<String?>(
//                   future: _storage.read(key: 'userPhotoUrl'),
//                   builder: (
//                     BuildContext context,
//                     AsyncSnapshot<String?> snapshot,
//                   ) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const CircleAvatar(radius: 20);
//                     } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
//                       return const CircleAvatar(
//                         radius: 20,
//                         child: Icon(Icons.person),
//                       );
//                     } else {
//                       return Padding(
//                         padding: const EdgeInsets.only(right: 16.0),
//                         child: CircleAvatar(
//                           radius: 20,
//                           backgroundImage: _getProfileImage(
//                             _profile?.photo,
//                             snapshot.data!,
//                           ),
//                           child: (_profile?.photo == null && snapshot.data == null)
//                               ? const Icon(Icons.person, color: Colors.white)
//                               : null,
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Builder(
//         builder: (context) {
//           switch (_bottomNavIndex) {
//             case 0:
//               return const ProductsPage();
//             case 1:
//               return const CartPage();
//             case 2:
//               return const OrdersPage();
//             case 3:
//               return const RestaurantsPage();
//             default:
//               return const Center(child: Text('Página no encontrada'));
//           }
//         },
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: _getBottomNavItems(),
//         currentIndex: _bottomNavIndex,
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.grey,
//         onTap: _onBottomNavTapped,
//       ),
//     );
//   }
// }

// ImageProvider<Object> _getProfileImage(String? profilePhoto, String? googlePhotoUrl) {
//   if (profilePhoto != null && profilePhoto.isNotEmpty) {
//     logger.i('Usando foto del perfil: $profilePhoto');
//     return NetworkImage(profilePhoto); // Imagen del perfil del usuario
//   }
//   if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
//     logger.i('Usando foto de Google: $googlePhotoUrl');
//     return NetworkImage(googlePhotoUrl); // Imagen de Google
//   }
//   logger.w('Usando imagen predeterminada');
//   return const AssetImage('assets/default_avatar.png'); // Imagen predeterminada
// }










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
import 'package:zonix/features/services/transport_service.dart';
import 'package:zonix/features/services/affiliate_service.dart';
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
import 'package:zonix/features/screens/transport/transport_fleet_page.dart';
import 'package:zonix/features/screens/transport/transport_orders_page.dart';
import 'package:zonix/features/screens/transport/transport_analytics_page.dart';
import 'package:zonix/features/screens/transport/transport_settings_page.dart';
import 'package:zonix/features/screens/affiliate/affiliate_dashboard_page.dart';
import 'package:zonix/features/screens/affiliate/affiliate_commissions_page.dart';
import 'package:zonix/features/screens/affiliate/affiliate_support_page.dart';
import 'package:zonix/features/screens/affiliate/affiliate_statistics_page.dart';
import 'package:zonix/features/screens/admin/admin_dashboard_page.dart';
import 'package:zonix/features/screens/admin/admin_users_page.dart';
import 'package:zonix/features/screens/admin/admin_security_page.dart';
import 'package:zonix/features/screens/admin/admin_analytics_page.dart';

import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/features/services/websocket_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/*
 * ZONIX EATS - Aplicación Multi-Rol
 * 
 * Niveles de usuario:
 * 0 - Comprador: Productos, Carrito, Mis Órdenes, Restaurantes
 * 1 - Tiendas/Comercio: Dashboard, Inventario, Órdenes, Reportes
 * 2 - Delivery: Entregas, Historial, Rutas, Ganancias
 * 3 - Agencia de Transporte: Flota, Conductores, Rutas, Métricas
 * 4 - Afiliado a Delivery: Afiliaciones, Comisiones, Soporte, Estadísticas
 * 5 - Administrador: Panel Admin, Usuarios, Seguridad, Sistema
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
  //  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => CommerceService()),
        ChangeNotifierProvider(create: (_) => DeliveryService()),
        ChangeNotifierProvider(create: (_) => TransportService()),
        ChangeNotifierProvider(create: (_) => AffiliateService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
        // WebSocket Service como singleton
        Provider<WebSocketService>.value(value: WebSocketService()),
      ],
      child: const MyApp(),
    ),
  );
}

void initialization() async {
  logger.i('Initializing...');
  await Future.delayed(const Duration(seconds: 3));
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).checkAuthentication();

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
      _selectedLevel = prefs.getInt('selectedLevel') ?? 0;
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
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Órdenes',
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
      case 3: // Agencia de Transporte
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Flota',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Pedidos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analíticas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ];
        break;
      case 4: // Afiliado a Delivery
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.percent),
            label: 'Comisiones',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Soporte',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Estadísticas',
          ),
        ];
        break;
      case 5: // Administrador
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

    // // Agregar elementos específicos según el rol si el nivel es 0
    // if (level == 0) {
    //   if (role == 'sales_admin') { 
    //     items.insert( 2, const BottomNavigationBarItem( icon: Icon(Icons.qr_code), label: 'Verificar', ),);
       
    //     items.insert( 3, const BottomNavigationBarItem( icon: Icon(Icons.check_circle), label: 'Aprobar', ),);
    //   }

    //   if (role == 'dispatcher') {
    //     items.insert(
    //       2,
    //       const BottomNavigationBarItem(
    //         icon: Icon(Icons.workspace_premium),
    //         label: 'Despachar',
    //       ),
    //     );
    //   }
    // }

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

                // if (_selectedLevel == 0) {
                //   if (_bottomNavIndex == 0) return const HelpAndFAQPage();
                //   if (_bottomNavIndex == 1) return const HelpAndFAQPage();
                //   if (_bottomNavIndex == 2 && role == 'sales_admin') return const TicketScannerScreen();
                //   if (_bottomNavIndex == 3 && role == 'sales_admin') return const CheckScannerScreen();
                //   if (_bottomNavIndex == 2 && role == 'dispatcher') return const DispatcherScreen();
                // }

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
                      return const CommerceInventoryPage(); // Inventario
                    case 2:
                      return const CommerceOrdersPage(); // Órdenes
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

                // Nivel 3: Agencia de Transporte
                if (_selectedLevel == 3) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return TransportFleetPage(); // Flota
                    case 1:
                      return const TransportOrdersPage(); // Gestión de Pedidos
                    case 2:
                      return const TransportAnalyticsPage(); // Analíticas
                    case 3:
                      return const TransportSettingsPage(); // Configuración
                    default:
                      return TransportFleetPage();
                  }
                }

                // Nivel 4: Afiliado a Delivery
                if (_selectedLevel == 4) {
                  switch (_bottomNavIndex) {
                    case 0:
                      return AffiliateDashboardPage(); // Dashboard
                    case 1:
                      return const AffiliateCommissionsPage(); // Comisiones
                    case 2:
                      return const AffiliateSupportPage(); // Soporte
                    case 3:
                      return const AffiliateStatisticsPage(); // Estadísticas
                    default:
                      return AffiliateDashboardPage();
                  }
                }

                // Nivel 5: Administrador
                if (_selectedLevel == 5) {
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
          _createLevelButton(3, Icons.local_shipping, 'Agencia de Transporte'),
          _createLevelButton(4, Icons.handshake, 'Afiliado a Delivery'),
          _createLevelButton(5, Icons.admin_panel_settings, 'Administrador'),
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
