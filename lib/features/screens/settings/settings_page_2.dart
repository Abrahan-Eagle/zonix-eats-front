import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Documents/screens/document_list_screen.dart';

import 'package:zonix/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:zonix/features/screens/about/about_page.dart';
import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
// Importaciones para funcionalidades avanzadas
import 'package:zonix/features/DomainProfiles/Profiles/screens/activity_history_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/data_export_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/privacy_settings_page.dart';
import 'package:zonix/features/screens/account_deletion_page.dart';
import 'package:zonix/features/utils/app_colors.dart';

import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:zonix/features/screens/settings/commerce_payment_page.dart';
import 'package:zonix/features/screens/settings/commerce_schedule_page.dart';
import 'package:zonix/features/screens/settings/commerce_open_page.dart';
import 'package:zonix/features/screens/commerce/commerce_promotions_page.dart';
import 'package:zonix/features/screens/commerce/commerce_zones_page.dart';
import 'package:zonix/features/screens/commerce/commerce_notifications_page.dart';


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
            title: const Text("Configuraciones"), // TODO: internacionalizar
            backgroundColor: AppColors.purple,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Colors.white,
            ),
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado de usuario destacado
                  Card(
                    color: AppColors.cardBg(context),
                    elevation: 8,
                    shadowColor: AppColors.purple.withOpacity(0.10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: _getProfileImage(_profile?.photo),
                            backgroundColor: AppColors.purple.withOpacity(0.15),
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
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: AppColors.primaryText(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email ?? 'Correo no disponible',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondaryText(context),
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
                    "Mi cuenta", // TODO: internacionalizar
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentButton(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.cardBg(context),
                    elevation: 6,
                    shadowColor: AppColors.orange.withOpacity(0.10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.person_outline_rounded,
                          color: AppColors.accentButton(context),
                          title: "Perfil", // TODO: internacionalizar
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
                          color: AppColors.purple,
                          title: "Documentos", // TODO: internacionalizar
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
                          color: AppColors.orange,
                          title: "Direcciones", // TODO: internacionalizar
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
                          color: AppColors.green,
                          title: "Teléfonos", // TODO: internacionalizar
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneScreen(userId: userProvider.userId),
                              ),
                            );
                          },
                        ),

                      ],
                    ),
                  ),
                  // Después de la sección 'Mi cuenta' y antes de 'Funcionalidades Avanzadas':
                  if (userProvider.userRole == 'commerce') ...[
                    const SizedBox(height: 24),
                    Text(
                      "Gestión del comercio",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.accentButton(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: AppColors.cardBg(context),
                      elevation: 6,
                      shadowColor: AppColors.purple.withOpacity(0.10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildListTile(
                            context,
                            icon: Icons.store,
                            color: AppColors.purple,
                            title: "Datos del comercio",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommerceDataPage(),
                                ),
                              );
                            },
                          ),
                          _buildListTile(
                            context,
                            icon: Icons.payment,
                            color: AppColors.green,
                            title: "Datos de pago móvil",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommercePaymentPage(),
                                ),
                              );
                            },
                          ),
                          _buildListTile(
                            context,
                            icon: Icons.schedule,
                            color: AppColors.orange,
                            title: "Horario de atención",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommerceSchedulePage(),
                                ),
                              );
                            },
                          ),
                          _buildListTile(
                            context,
                            icon: Icons.toggle_on,
                            color: AppColors.red,
                            title: "Estado abierto/cerrado",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommerceOpenPage(),
                                ),
                              );
                            },
                          ),


                          _buildListTile(
                            context,
                            icon: Icons.local_offer,
                            color: AppColors.red,
                            title: "Promociones/Cupones",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommercePromotionsPage(),
                                ),
                              );
                            },
                          ),

                          _buildListTile(
                            context,
                            icon: Icons.map,
                            color: AppColors.brown,
                            title: "Zonas/costos de delivery",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommerceZonesPage(),
                                ),
                              );
                            },
                          ),
                          _buildListTile(
                            context,
                            icon: Icons.notifications,
                            color: AppColors.amber,
                            title: "Notificaciones y alertas",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommerceNotificationsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Sección: Funcionalidades Avanzadas
                  Text(
                    "Funcionalidades Avanzadas", // TODO: internacionalizar
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentButton(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.cardBg(context),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.history,
                          color: AppColors.accentButton(context),
                          title: "Historial de Actividad", // TODO: internacionalizar
                          subtitle: "Revisa todas tus actividades en la aplicación", // TODO: internacionalizar
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
                          color: AppColors.green,
                          title: "Exportar Datos", // TODO: internacionalizar
                          subtitle: "Descarga una copia de todos tus datos personales", // TODO: internacionalizar
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
                          color: AppColors.orange,
                          title: "Configuración de Privacidad", // TODO: internacionalizar
                          subtitle: "Controla cómo se utilizan y comparten tus datos", // TODO: internacionalizar
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
                          color: AppColors.red,
                          title: "Eliminación de Cuenta", // TODO: internacionalizar
                          subtitle: "Solicitar eliminación permanente de tu cuenta", // TODO: internacionalizar
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
                    "Administración y Ayuda", // TODO: internacionalizar
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentButton(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.cardBg(context),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.notifications_none_rounded,
                          color: AppColors.purple,
                          title: "Notificaciones", // TODO: internacionalizar
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
                          color: AppColors.purple,
                          title: "Ayuda y Comentarios", // TODO: internacionalizar
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
                          color: AppColors.gray,
                          title: "Acerca de", // TODO: internacionalizar
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
                          "Cerrar sesión", // TODO: internacionalizar
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
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
        child: Icon(icon, color: color, size: 24),
        radius: 20,
      ),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }


ImageProvider<Object> _getProfileImage(String? profilePhoto) {
  if (profilePhoto != null && profilePhoto.isNotEmpty) {
    // Detectar URLs de placeholder y evitarlas
    if (profilePhoto.contains('via.placeholder.com') || 
        profilePhoto.contains('placeholder.com') ||
        profilePhoto.contains('placehold.it')) {
      logger.w('Detectada URL de placeholder, usando imagen local: $profilePhoto');
      return const AssetImage('assets/default_avatar.png');
    }
    
    logger.i('Usando foto del perfil: $profilePhoto');
    return NetworkImage(profilePhoto); 
  }

  logger.w('Usando imagen predeterminada');
  return const AssetImage('assets/default_avatar.png'); 
}
}