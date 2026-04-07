




import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/app/fcm_bootstrap.dart';
import 'package:zonix/app/main_router.dart';
import 'package:zonix/app/notification_navigation.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_page.dart';
import 'package:zonix/features/screens/commerce/commerce_order_detail_page.dart';
import 'package:zonix/features/screens/commerce/commerce_orders_page.dart';
import 'package:zonix/features/screens/commerce/commerce_product_form_page.dart';
import 'package:zonix/features/screens/commerce/commerce_products_page.dart';
import 'package:zonix/features/screens/commerce/commerce_profile_page.dart';
import 'package:zonix/features/screens/commerce/commerce_reports_page.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';
import 'package:zonix/features/screens/onboarding/onboarding_provider.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/restaurants/restaurants_page.dart';
import 'package:zonix/features/services/admin_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/commerce_analytics_service.dart';
import 'package:zonix/features/services/commerce_service.dart';
import 'package:zonix/features/services/connectivity_service.dart';
import 'package:zonix/features/services/delivery_company_service.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/utils/app_theme.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/models/commerce_product.dart';
import 'package:zonix/models/order.dart';

/*
 * ZONIX EATS - Aplicación Multi-Rol
 *
 * Niveles de usuario (según roles):
 * 0 - Comprador (users): Productos, Carrito, Mis Órdenes, Restaurantes
 * 1 - Comercio: Dashboard, Órdenes, Productos, Reportes
 * 2 - Delivery: Entregas, Historial, Rutas, Ganancias
 * 3 - Empresa de Delivery: Dashboard, Agentes, Órdenes, Mapa
 * 4 - Admin: Dashboard, Usuarios, Órdenes, Analytics
 */

/// Re-export para código que importa `showLocalNotification` desde main.
export 'package:zonix/app/fcm_bootstrap.dart' show showLocalNotification;

// Configuración del logger
final logger = Logger();

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initLocalNotifications();
  await initFcmToken();
  registerFcmForegroundListeners();

  initialization();
  await initializeDateFormatting('es');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        ChangeNotifierProvider(create: (_) => DeliveryCompanyService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => CommerceAnalyticsService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: isIntegrationTest
          ? const MyApp(isIntegrationTest: true)
          : const MyApp(),
    ),
  );
}

void initialization() async {
  logger.i('Initializing...');
  await Future.delayed(const Duration(milliseconds: 400));
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  final bool isIntegrationTest;
  const MyApp({super.key, this.isIntegrationTest = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialAuthScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialAuthScheduled) return;
    _initialAuthScheduled = true;

    if (widget.isIntegrationTest) {
      context.read<UserProvider>().setAuthenticatedForTest(role: 'commerce');
    } else {
      context.read<UserProvider>().checkAuthentication();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Zonix Eats',
      debugShowCheckedModeBanner: false,
      theme: buildStitchLightTheme(),
      darkTheme: buildStitchDarkTheme(),
      themeMode: ThemeMode.system,
      builder: (context, child) => child ?? const SizedBox.shrink(),
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
        '/commerce/notifications': (context) => const NotificationsPage(),
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
