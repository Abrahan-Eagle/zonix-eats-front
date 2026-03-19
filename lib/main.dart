




import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';
import 'package:zonix/features/utils/bottom_nav_persistence.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:zonix/models/notification_item.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

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
import 'package:zonix/features/screens/notifications/notifications_page.dart';
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

// Configuración del logger
final logger = Logger();

/// Llave global para navegar desde callbacks sin context (ej. al tocar notificación FCM).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navega según el payload de la notificación (order_id, type: order|chat|commerce_order).
/// Para chat, redirige a la pantalla correcta según el rol del usuario.
void _navigateFromNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    return;
  }
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>?;
    if (data == null) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      return;
    }
    final orderId = data['order_id'] != null ? int.tryParse(data['order_id'].toString()) : null;
    final type = data['type']?.toString() ?? '';

    if (orderId != null && orderId > 0) {
      if (type == 'commerce_order') {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => CommerceOrderDetailPage(orderId: orderId),
        ));
      } else if (type == 'chat') {
        _navigateToChatByRole(orderId, data);
      } else {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: orderId, order: null),
        ));
      }
    } else {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    }
  } catch (_) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }
}

/// Abre la pantalla de chat correcta según el rol del usuario autenticado.
void _navigateToChatByRole(int orderId, Map<String, dynamic> data) {
  final ctx = navigatorKey.currentContext;
  final role = ctx != null
      ? Provider.of<UserProvider>(ctx, listen: false).userRole
      : '';
  final senderName = data['sender_name']?.toString() ?? '';

  if (role == 'commerce') {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => CommerceChatMessagesPage(
        orderId: orderId,
        customerName: senderName.isNotEmpty ? senderName : 'Cliente',
      ),
    ));
  } else {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => BuyerOrderChatPage(orderId: orderId),
    ));
  }
}

/// Navega desde un RemoteMessage (app abierta desde notificación en background/terminated).
void _navigateFromRemoteMessage(RemoteMessage message) {
  final data = message.data;
  if (data.isEmpty) {
    _navigateFromNotificationPayload(null);
    return;
  }
  _navigateFromNotificationPayload(jsonEncode(data));
}

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

/// ID del canal de notificaciones (sonido + vibración).
const String _fcmNotificationChannelId = 'zonix_eats_fcm';
const String _fcmNotificationChannelName = 'Notificaciones Zonix Eats';

/// true = usa res/raw/zonix_notification.mp3; false = sonido por defecto del sistema.
const bool _useCustomNotificationSound = true;

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

AndroidNotificationChannel _buildFcmChannel() {
  return const AndroidNotificationChannel(
    _fcmNotificationChannelId,
    _fcmNotificationChannelName,
    description: 'Notificaciones push de pedidos y mensajes',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: _useCustomNotificationSound ? RawResourceAndroidNotificationSound('zonix_notification') : null,
  );
}

AndroidNotificationDetails _buildFcmNotificationDetails() {
  return const AndroidNotificationDetails(
    _fcmNotificationChannelId,
    _fcmNotificationChannelName,
    channelDescription: 'Notificaciones push de pedidos y mensajes',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    showWhen: true,
    sound: _useCustomNotificationSound ? RawResourceAndroidNotificationSound('zonix_notification') : null,
  );
}

/// Crea el canal de notificaciones con sonido y vibración (Android).
Future<void> _createFcmNotificationChannel() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return;
  await androidPlugin.createNotificationChannel(_buildFcmChannel());
}

/// Muestra una notificación local con sonido, vibración y [payload] para navegación al tocar.
Future<void> _showFcmNotification({
  required String title,
  required String body,
  int id = 0,
  String? payload,
}) async {
  final details = NotificationDetails(android: _buildFcmNotificationDetails());
  await _localNotifications.show(id, title, body, details, payload: payload);
}

/// Inicializa notificaciones locales (canal con sonido y vibración).
Future<void> _initLocalNotifications() async {
  if (kIsWeb) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null && response.payload!.isNotEmpty) {
        _navigateFromNotificationPayload(response.payload);
      } else {
        _navigateFromNotificationPayload(null);
      }
    },
  );
  await _createFcmNotificationChannel();
}

/// Handler de mensajes FCM en segundo plano (debe ser función top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.i('FCM background: ${message.messageId}');

  // Mostrar notificación con sonido y vibración en background
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(InitializationSettings(android: android));
  final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(_buildFcmChannel());
  }
  final title = message.notification?.title ?? message.data['title'] ?? 'Zonix Eats';
  final body = message.notification?.body ?? message.data['body'] ?? 'Nueva notificación';
  await plugin.show(
    message.hashCode % 0x7FFFFFFF,
    title,
    body,
    NotificationDetails(android: _buildFcmNotificationDetails()),
  );
}

/// Solicita permiso de notificaciones, obtiene el token FCM y lo guarda en almacenamiento seguro.
/// En Android 13+ pide POST_NOTIFICATIONS; el backend recibe el token vía UserProvider._registerFcmToken().
Future<void> _initFcmToken() async {
  if (kIsWeb) return;
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        logger.w('FCM: permiso de notificaciones no concedido');
        return;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        logger.w('FCM: permiso iOS no concedido');
        return;
      }
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _secureStorage.write(key: 'fcm_token', value: token);
      logger.i('FCM token guardado');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty) {
        await _secureStorage.write(key: 'fcm_token', value: newToken);
        logger.i('FCM token actualizado');
      }
    });
  } catch (e) {
    logger.w('FCM init error: $e');
  }
}

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initLocalNotifications();
  await _initFcmToken();

  // Foreground: mostrar notificación con sonido/vibración y payload para navegación al tocar
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Zonix Eats';
    final body = message.notification?.body ?? message.data['body'] ?? 'Nueva notificación';
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    _showFcmNotification(
      title: title,
      body: body,
      id: message.hashCode % 0x7FFFFFFF,
      payload: payload,
    );
  });

  // App abierta desde notificación (estaba en background)
  FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromRemoteMessage);

  initialization();
  await initializeDateFormatting('es');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

// Paleta Stitch (template) — centralizada en AppColors
const Color _stitchPrimary = AppColors.blue;
const Color _stitchBgLight = AppColors.scaffoldBgLight;
const Color _stitchBgDark = AppColors.backgroundDark;
const Color _stitchSurfaceDark = AppColors.grayDark;
const Color _stitchCardCream = AppColors.stitchCardCream;
const Color _stitchNavBg = AppColors.stitchNavBg;
const Color _stitchNavActive = AppColors.blue;
const Color _stitchSlate400 = AppColors.stitchSlate400;

ThemeData _buildStitchLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    primaryColor: _stitchPrimary,
    scaffoldBackgroundColor: _stitchBgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: _stitchPrimary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    colorScheme: const ColorScheme.light(
      primary: _stitchPrimary,
      secondary: AppColors.orange,
      error: AppColors.red,
      surface: _stitchBgLight,
      onPrimary: AppColors.white,
      onSurface: AppColors.stitchTextDark,
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
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _stitchPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
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
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: _stitchPrimary,
      secondary: AppColors.orangeCoral,
      error: AppColors.red,
      surface: _stitchSurfaceDark,
      onPrimary: AppColors.white,
      onSurface: AppColors.white,
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
        foregroundColor: AppColors.white,
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
      navigatorKey: navigatorKey,
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
  /// Rol para el que ya se cargó la posición guardada (evita recargas).
  String? _positionLoadedForRole;
  StreamSubscription<NotificationItem>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifService = context.read<NotificationService>();
      notifService.loadInitialData();

      // Escuchar nuevas notificaciones en tiempo real para mostrar feedback global
      _notificationSubscription = notifService.newNotificationStream.listen((n) {
        if (mounted) {
          _showGlobalNotification(n);
        }
      });

      // Si la app se abrió tocando una notificación (estaba cerrada), navegar
      if (!kIsWeb) {
        FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
          if (message != null && mounted) _navigateFromRemoteMessage(message);
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

    // Si estamos en la página de notificaciones, no mostramos el snackbar para evitar ruido
    // (ya se verá en la lista directamente) - opcional según UX deseada.
    
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
        logger.e('Error obteniendo el perfil: $e');
      }
    }

  Future<void> _loadLastPosition() async {
    // Sin rol aún: dejamos índice en 0; la posición por rol se carga en build() cuando haya rol.
    if (!mounted) return;
    setState(() {
      _bottomNavIndex = 0;
      logger.i('Loaded last position - bottomNavIndex: 0 (sin rol aún)');
    });
  }

  /// Carga la última posición guardada para [role] (clave bottomNavIndex_$role).
  Future<void> _loadPositionForRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final key = bottomNavStorageKey(role);
    final value = prefs.getInt(key) ?? 0;
    if (!mounted) return;
    setState(() {
      _bottomNavIndex = value;
      _positionLoadedForRole = role;
      logger.i('Loaded last position for $role - bottomNavIndex: $value');
    });
  }

  /// Guarda el índice de la bottom nav por rol. Si [index] se pasa, se guarda ese valor.
  /// [role] si no se pasa se toma del UserProvider (debe estar disponible en build/tap).
  Future<void> _saveLastPosition([int? index, String? role]) async {
    final valueToSave = index ?? _bottomNavIndex;
    final r = role ?? Provider.of<UserProvider>(context, listen: false).userRole;
    final key = bottomNavStorageKey(r);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, valueToSave);
    if (!mounted) return;
    logger.i('Saved last position for ${r.isEmpty ? 'users' : r} - bottomNavIndex: $valueToSave');
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
        _saveLastPosition(index); // Guardar el índice actual para no pisarlo en async
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Calcular niveles permitidos según el rol del usuario
    final rawRole = userProvider.userRole;
    final role = rawRole.isEmpty ? 'users' : rawRole;

    // Solo sincronizar _lastRole cuando tenemos un rol real del backend (no vacío).
    // Si userRole está vacío estamos en carga y no debemos guardar 'users' como _lastRole,
    // o en el siguiente build pensaremos que el rol "cambió" y resetearemos la pestaña a 0.
    if (rawRole.isNotEmpty && _lastRole != role) {
      final wasUnset = _lastRole?.isEmpty ?? true;
      _lastRole = role;
      _positionLoadedForRole = null; // cargar de nuevo para este rol
      _allowedLevels = levelsForRole(role);
      _selectedLevel = defaultLevelForRole(role);
      if (!wasUnset) {
        _bottomNavIndex = 0;
        _saveLastPosition(0, role);
      }
      _loadPositionForRole(role);
    } else if (rawRole.isNotEmpty && _positionLoadedForRole != role) {
      // Primera vez que tenemos rol en esta sesión: cargar posición guardada para este rol
      _loadPositionForRole(role);
    } else if (_allowedLevels.isEmpty) {
      // Primera vez que se calculan los niveles permitidos
      _allowedLevels = levelsForRole(role);
      if (!_allowedLevels.contains(_selectedLevel)) {
        _selectedLevel = defaultLevelForRole(role);
        _bottomNavIndex = 0;
        _saveLastPosition(0, role);
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
                        : const Color(0xFF0F172A),
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
                _selectedLevel = defaultLevelForRole(role);

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
