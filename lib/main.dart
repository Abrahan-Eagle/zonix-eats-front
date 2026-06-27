import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix_glasses/app/fcm_bootstrap.dart';
import 'package:zonix_glasses/app/main_router.dart';
import 'package:zonix_glasses/app/notification_navigation.dart';
import 'package:zonix_glasses/config/app_config.dart';
import 'package:zonix_glasses/features/screens/auth/sign_in_screen.dart';
import 'package:zonix_glasses/features/screens/onboarding/onboarding_screen.dart';
import 'package:zonix_glasses/features/screens/onboarding/onboarding_provider.dart';
import 'package:zonix_glasses/features/services/connectivity_service.dart';
import 'package:zonix_glasses/features/services/notification_service.dart';
import 'package:zonix_glasses/features/utils/app_theme.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

export 'package:zonix_glasses/app/fcm_bootstrap.dart' show showLocalNotification;

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

  await initializeDateFormatting('es');
  await Future.delayed(const Duration(milliseconds: 400));
  FlutterNativeSplash.remove();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  const isIntegrationTest =
      String.fromEnvironment('INTEGRATION_TEST', defaultValue: 'false') == 'true';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: MyApp(isIntegrationTest: isIntegrationTest),
    ),
  );
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
      context.read<UserProvider>().setAuthenticatedForTest(role: 'user');
    } else {
      context.read<UserProvider>().checkAuthentication();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildStitchLightTheme(),
      darkTheme: buildStitchDarkTheme(),
      themeMode: ThemeMode.system,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (!userProvider.isAuthenticated) {
            return const SignInScreen();
          }
          if (!userProvider.completedOnboarding) {
            return const OnboardingScreen();
          }
          return const MainRouter();
        },
      ),
    );
  }
}
