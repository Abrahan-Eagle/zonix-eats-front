import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Documents/screens/document_list_screen.dart';
import 'package:zonix/features/DomainProfiles/Emails/screens/email_list_screen.dart';
import 'package:zonix/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:zonix/features/screens/about/about_page.dart';
import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/screens/onboarding/form/commerce_registration_page.dart';
import 'package:zonix/features/screens/onboarding/form/delivery_company_registration_page.dart';
import 'package:zonix/features/screens/onboarding/form/delivery_agent_registration_page.dart';
// Importaciones para funcionalidades avanzadas
import 'package:zonix/features/DomainProfiles/Profiles/screens/activity_history_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/data_export_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/privacy_settings_page.dart';
import 'package:zonix/features/screens/account_deletion_page.dart';

// Configuración del logger
final logger = Logger();



class SettingsPage2 extends StatefulWidget {
  const SettingsPage2({super.key});

  @override
  State<SettingsPage2> createState() => _SettingsPage2State();
}


class _SettingsPage2State extends State<SettingsPage2> {
  dynamic _profile;
  String? _email;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Future<void> _loadProfile() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //   try {
  //     final userProvider = Provider.of<UserProvider>(context, listen: false);
  //     final userDetails = await userProvider.getUserDetails();
  //     final id = userDetails['userId'];
  //     if (id == null || id is! int) {
  //       throw Exception('El ID del usuario es inválido: $id');
  //     }
  //     _email = userDetails['users']['email'];
  //     _profile = await ProfileService().getProfileById(id);
  //     logger.e('Error obteniendo el ID del usuario: $_profile');
  //   } catch (e) {
  //     logger.e('Error obteniendo el ID del usuario: $e');
  //     _error = 'Error al cargar el perfil';
  //   } finally {
  //     setState(() {
  //       _loading = false;
  //     });
  //   }
  // }

  Future<void> _loadProfile() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userDetails = await userProvider.getUserDetails();
    
    // More flexible ID handling
    final id = userDetails['userId'];
    if (id == null) {
      throw Exception('No se pudo obtener el ID del usuario');
    }
    
    // Convert to int if necessary
    final userId = id is int ? id : int.tryParse(id.toString());
    if (userId == null) {
      throw Exception('El ID del usuario no es válido: $id');
    }
    
    _email = userDetails['users']['email'];
    _profile = await ProfileService().getProfileById(userId);
    
    // Log success as info, not error
    logger.i('Perfil cargado correctamente: $_profile');
    
  } catch (e, stackTrace) {
    // logger.e('Error al cargar el perfil', error: e, stackTrace: stackTrace);
    setState(() {
      // _error = 'Error al cargar el perfil: ${e.toString()}';
    });
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Configuraciones")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Configuraciones"),
            backgroundColor: theme.colorScheme.primaryContainer,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Colors.white,
            ),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado de usuario destacado
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: _getProfileImage(_profile?.photo),
                            child: (_profile?.photo == null)
                                ? const Icon(Icons.person, color: Colors.white, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email ?? 'Correo no disponible',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sección: Información de cuenta
                  Text(
                    "Mi cuenta",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.person_outline_rounded,
                          color: Colors.blue,
                          title: "Perfil",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePagex(userId: userProvider.userId),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.folder_outlined,
                          color: Colors.deepPurple,
                          title: "Documentos",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DocumentListScreen(userId: userProvider.userId),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.location_on_outlined,
                          color: Colors.teal,
                          title: "Dirección",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddressPage(userId: userProvider.userId),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.phone_outlined,
                          color: Colors.green,
                          title: "Teléfonos",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneScreen(userId: userProvider.userId),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.email_outlined,
                          color: Colors.orange,
                          title: "Correos electrónicos",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmailListScreen(userId: userProvider.userId),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección: Funcionalidades Avanzadas
                  Text(
                    "Funcionalidades Avanzadas",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.history,
                          color: Colors.blue,
                          title: "Historial de Actividad",
                          subtitle: "Revisa todas tus actividades en la aplicación",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ActivityHistoryPage(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.download,
                          color: Colors.green,
                          title: "Exportar Datos",
                          subtitle: "Descarga una copia de todos tus datos personales",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DataExportPage(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.privacy_tip,
                          color: Colors.orange,
                          title: "Configuración de Privacidad",
                          subtitle: "Controla cómo se utilizan y comparten tus datos",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacySettingsPage(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.delete_forever,
                          color: Colors.red,
                          title: "Eliminación de Cuenta",
                          subtitle: "Solicitar eliminación permanente de tu cuenta",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountDeletionPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección: Administración y Ayuda
                  Text(
                    "Administración y Ayuda",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.notifications_none_rounded,
                          color: Colors.purple,
                          title: "Notificaciones",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          color: Colors.indigo,
                          title: "Ayuda y Comentarios",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpAndFAQPage(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: Icons.info_outline_rounded,
                          color: Colors.grey,
                          title: "Acerca de",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyApp(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón de cerrar sesión
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await userProvider.logout();
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.logout_sharp,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: const Text(
                          "Cerrar sesión",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required Color color, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color, size: 28),
        radius: 22,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }


ImageProvider<Object> _getProfileImage(String? profilePhoto) {
  if (profilePhoto != null && profilePhoto.isNotEmpty) {
    logger.i('Usando foto del perfil: $profilePhoto');
    return NetworkImage(profilePhoto); 
  }

  logger.w('Usando imagen predeterminada');
  return const AssetImage('assets/default_avatar.png'); 
}
}