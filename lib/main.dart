import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix/features/services/auth/api_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/screens/sign_in_screen.dart';

import 'package:zonix/features/ScreenDashboard/buyer/buyer_dashboard.dart';
import 'package:zonix/features/ScreenDashboard/commerce/commerce_dashboard.dart';
import 'package:zonix/features/ScreenDashboard/delivery_agent/delivery_agent_dashboard.dart';
import 'package:zonix/features/ScreenDashboard/delivery_company/delivery_company_dashboard.dart';
import 'package:zonix/features/ScreenDashboard/admin/admin_dashboard.dart';
import 'package:zonix/features/ScreenDashboard/users/users_dashboard.dart';



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
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          logger.i('isAuthenticated: ${userProvider.isAuthenticated}');
          logger.i('isRoles: ${userProvider.userRole}');
          
          if (userProvider.isAuthenticated || userProvider.userRole.isNotEmpty) {
            final role = userProvider.userRole;
          
            switch (role) {
              case 'buyer':
                logger.d('**********************************************BuyerDashboard**********************************************');
                return  const BuyerDashboard();
              case 'commerce':
                logger.d('**********************************************CommerceDashboard*******************************************');
                return const CommerceDashboard();
              case 'delivery_company':
                logger.d('**********************************************DeliveryCompanyDashboard************************************');
                return const DeliveryCompanyDashboard();
              case 'delivery_agent':
                logger.d('**********************************************DeliveryAgentDashboard**************************************');
                return const DeliveryAgentDashboard();
              case 'admin':
                logger.d('**********************************************AdminDashboard**********************************************');
                return const AdminDashboard(); 
              case 'users':
                logger.d('**********************************************UsersDashboard**********************************************');
                return const UsersDashboard();
              default:
                logger.d('**********************************************DEFAULT*****************************************************');
                return const UsersDashboard(); 
            }

          } else {
            return const SignInScreen();
          }
        },
      ),
    );
  }
}
