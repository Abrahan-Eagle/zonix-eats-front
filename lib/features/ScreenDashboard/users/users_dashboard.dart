import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/screens/profile_page.dart';
import 'package:zonix/features/screens/settings_page_2.dart';
import 'package:zonix/features/screens/sign_in_screen.dart';
import 'package:zonix/features/GasTicket/another_button/screens/other_screen.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();
final logger = Logger();

class UsersDashboard extends StatefulWidget {
  const UsersDashboard({super.key});

  @override
  UsersDashboardState createState() => UsersDashboardState();
}

class UsersDashboardState extends State<UsersDashboard> {
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
      final userDetails = await userProvider.getUserDetails();
      final id = userDetails['userId'];
      if (id == null || id is! int) {
        throw Exception('El ID del usuario es inválido: $id');
      }
      // _profile = await ProfileService().getProfileById(id);
      setState(() {});
    } catch (e) {
      logger.e('Error obteniendo el ID del usuario: $e');
    }
  }

  Future<void> _loadLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _bottomNavIndex = prefs.getInt('bottomNavIndex') ?? 0;
      logger.i('Loaded last position - bottomNavIndex: $_bottomNavIndex');
    });
  }

  Future<void> _saveLastPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bottomNavIndex', _bottomNavIndex);
    logger.i('Saved last position - bottomNavIndex: $_bottomNavIndex');
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String role) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.help),
        label: 'Ayuda',
      ),
    ];

    // Agregar el item de configuración siempre al final
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Configuración',
      ),
    );

    return items;
  }

  void _onBottomNavTapped(int index, int itemCount) {
    logger.i('Bottom navigation tapped: $index, Total items: $itemCount');

    if (index == itemCount - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage2()),
      );
    } else {
      setState(() {
        _bottomNavIndex = index;
        logger.i('Bottom nav index changed to: $_bottomNavIndex');
        _saveLastPosition();
      });
    }
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
                  color: Theme.of(context).brightness == Brightness.dark
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
                  color: Theme.of(context).brightness == Brightness.dark
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage1(),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        child: const Text('Configuración'),
                        onTap: () => Navigator.push(
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
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                            (Route<dynamic> route) => false,
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
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: _getProfileImage(
                            _profile?.photo,
                            snapshot.data!,
                          ),
                          child: (_profile?.photo == null && snapshot.data == null)
                              ? const Icon(Icons.person, color: Colors.white)
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
              } else {
                final role = userProvider.userRole;
                logger.i('Role fetched: $role');

                if (_bottomNavIndex == 0) return const OtherScreen();
                if (_bottomNavIndex == 1) return const OtherScreen();

                return const Center(
                  child: Text('Rol no reconocido o página no encontrada'),
                );
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _getBottomNavItems(userProvider.userRole),
        currentIndex: _bottomNavIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          List<BottomNavigationBarItem> items = _getBottomNavItems(userProvider.userRole);
          int itemCount = items.length;
          _onBottomNavTapped(index, itemCount);
        },
      ),
    );
  }
}

ImageProvider<Object> _getProfileImage(String? profilePhoto, String? googlePhotoUrl) {
  if (profilePhoto != null && profilePhoto.isNotEmpty) {
    logger.i('Usando foto del perfil: $profilePhoto');
    return NetworkImage(profilePhoto);
  }
  if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
    logger.i('Usando foto de Google: $googlePhotoUrl');
    return NetworkImage(googlePhotoUrl);
  }
  logger.w('Usando imagen predeterminada');
  return const AssetImage('assets/default_avatar.png');
}