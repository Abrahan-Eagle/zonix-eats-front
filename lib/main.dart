import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:logger/logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix_eats/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:flutter/services.dart';
import 'package:zonix_eats/features/screens/profile_page.dart';
import 'package:zonix_eats/features/screens/settings_page_2.dart';
import 'package:zonix_eats/features/screens/sign_in_screen.dart';
import 'package:zonix_eats/features/GasTicket/another_button/screens/other_screen.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/screens/gas_ticket_list_screen.dart'; // Asegúrate de importar esta pantalla
// import 'dart:io';
// import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix_eats/features/GasTicket/sales_admin/order_tracking/screens/ticket_scanner_screen.dart';
import 'package:zonix_eats/features/GasTicket/dispatch_ticket_button/screens/dispatch_ticket_scanner_screen.dart';
import 'package:zonix_eats/features/GasTicket/sales_admin/data_verification/screens/check_scanner_screen.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/api/profile_service.dart';

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
      case 1:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ayuda1',
          ),
        ];
        break;
      case 2:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ayuda2',
          ),
        ];
        break;
      case 3:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ayuda3',
          ),
        ];
        break;
      case 4:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ayuda4',
          ),
        ];
        break;
      case 5:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ayuda5',
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
            label: 'Ayuda0',
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

    // Agregar elementos específicos según el rol si el nivel es 0
    if (level == 0) {
      if (role == 'sales_admin') { 
        items.insert( 2, const BottomNavigationBarItem( icon: Icon(Icons.qr_code), label: 'Verificar', ),);
       
        items.insert( 3, const BottomNavigationBarItem( icon: Icon(Icons.check_circle), label: 'Aprobar', ),);
      }

      if (role == 'dispatcher') {
        items.insert(
          2,
          const BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium),
            label: 'Despachar',
          ),
        );
      }
    }

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

                if (_selectedLevel == 0) {
                  if (_bottomNavIndex == 0) return const GasTicketListScreen();
                  if (_bottomNavIndex == 1) return const OtherScreen();
                  if (_bottomNavIndex == 2 && role == 'sales_admin') return const TicketScannerScreen();
                  if (_bottomNavIndex == 3 && role == 'sales_admin') return const CheckScannerScreen();
                  if (_bottomNavIndex == 2 && role == 'dispatcher') return const DispatcherScreen();
                }

                if (_selectedLevel == 1) {
                  if (_bottomNavIndex == 0) return const GasTicketListScreen();
                  if (_bottomNavIndex == 1) return const OtherScreen();
                }

                if (_selectedLevel == 2) {
                  if (_bottomNavIndex == 0) return const GasTicketListScreen();
                  if (_bottomNavIndex == 1) return const OtherScreen();
                }

                if (_selectedLevel == 3) {
                  if (_bottomNavIndex == 0) return const GasTicketListScreen();
                  if (_bottomNavIndex == 1) return const OtherScreen();
                }

                if (_selectedLevel == 4) {
                  if (_bottomNavIndex == 0) return const GasTicketListScreen();
                  if (_bottomNavIndex == 1) return const OtherScreen();
                }

                if (_selectedLevel == 5) {
                  if (_bottomNavIndex == 0) return const GasTicketListScreen();
                  if (_bottomNavIndex == 1) return const OtherScreen();
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
          _createLevelButton(0, Icons.propane_tank, 'GAS'),
          _createLevelButton(1, Icons.attach_money, 'Dólares Compra/Venta'),
          _createLevelButton(2, Icons.local_police, '911'),
          _createLevelButton(3, Icons.fastfood, 'Comida Rápida'),
          _createLevelButton(4, Icons.store, 'Tiendas'),
          _createLevelButton(5, Icons.local_taxi, 'Taxis'),
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
