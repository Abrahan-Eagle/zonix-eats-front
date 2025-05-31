

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
// import 'package:zonix/features/DomainProfiles/Documents/screens/document_list_screen.dart';
// import 'package:zonix/features/DomainProfiles/Emails/screens/email_list_screen.dart';
// import 'package:zonix/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';
// import 'package:zonix/features/DomainProfiles/GasCylinder/screens/gas_cylinder_list_screen.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix/features/screens/sign_in_screen.dart';
// import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:zonix/features/screens/about/about_page.dart';
import 'package:zonix/features/screens/HelpAndFAQPage/help_and_faq_page.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';

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
 


@override
  void initState() {
    super.initState();
   _loadProfile();
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

        _email = userDetails['users']['email'];
        // Obtén el perfil usando el ID del usuario
        // _profile = await ProfileService().getProfileById(id);
            
        setState(() {});
      } catch (e) {
        logger.e('Error obteniendo el ID del usuario: $e');
      }
    }


@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      return Scaffold(
        // appBar: AppBar(
        //   title: const Text("Configuraciones"),
        //   backgroundColor: theme.colorScheme.primaryContainer,
        // ),

        appBar: AppBar(
          title: const Text("Configuraciones"),
          backgroundColor: theme.colorScheme.primaryContainer,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, // Negrita
            fontSize: 26, // Tamaño del texto
            color: Colors.white, // Texto blanco
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material con información de usuario
              Material(
                color: Colors.transparent,
                elevation: 2,
                child: Container(
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            // child: Image.network(
                            //   'https://images.unsplash.com/photo-1658932447624-152eaf36cf4e?w=500&h=500',
                            //   width: 60,
                            //   height: 60,
                            //   fit: BoxFit.cover,
                            // ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: _getProfileImage(
                                _profile?.photo, 
                              ),
                              child: (_profile?.photo == null)
                                  ? const Icon(Icons.person, color: Colors.white) // Ícono predeterminado
                                  : null,
                            ),

                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                Text(
                                    '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}', // Concatenar con espacio entre nombres
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),

                            Text(
                              _email ?? 'Correo no disponible', // Usamos _email si está disponible
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sección de Configuración General
              // Material(
              //   color: Colors.transparent,
              //   elevation: 2,
              //   child: Container(
              //     width: MediaQuery.sizeOf(context).width,
              //     decoration: BoxDecoration(
              //       color: theme.colorScheme.background,
              //       borderRadius: BorderRadius.circular(8.0),
              //     ),
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           "Configuración General",
              //           style: theme.textTheme.titleMedium?.copyWith(
              //             color: theme.colorScheme.primary,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         const SizedBox(height: 16),
              //         ...[
              //           {
              //             "title": "Perfil",
              //             "icon": Icons.person_outline_rounded,
              //             "onTap": () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       ProfilePagex(userId: userProvider.userId),
              //                 ),
              //               );
              //             },
              //           },
              //           {
              //             "title": "Documentos",
              //             "icon": Icons.folder_outlined,
              //             "onTap": () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       DocumentListScreen(userId: userProvider.userId),
              //                 ),
              //               );
              //             },
              //           },
              //           {
              //             "title": "Dirección",
              //             "icon": Icons.location_on_outlined,
              //             "onTap": () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       AddressPage(userId: userProvider.userId),
              //                 ),
              //               );
              //             },
              //           },
              //           {
              //             "title": "Bombonas de gas",
              //             "icon": Icons.local_gas_station_outlined,
              //             "onTap": () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       GasCylinderListScreen(userId: userProvider.userId),
              //                 ),
              //               );
              //             },
              //           },
              //           {
              //             "title": "Teléfonos",
              //             "icon": Icons.phone_outlined,
              //             "onTap": () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       PhoneScreen(userId: userProvider.userId),
              //                 ),
              //               );
              //             },
              //           },
              //           {
              //             "title": "Correos electrónicos",
              //             "icon": Icons.email_outlined,
              //             "onTap": () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) =>
              //                       EmailListScreen(userId: userProvider.userId),
              //                 ),
              //               );
              //             },
              //           },
              //         ].map((item) {
              //           return ListTile(
              //             leading: Icon(
              //               item["icon"] as IconData,
              //               color: theme.colorScheme.primary,
              //             ),
              //             title: Text(
              //               item["title"] as String,
              //               style: theme.textTheme.bodyMedium?.copyWith(
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //             trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              //             onTap: item["onTap"] as GestureTapCallback?,
              //           );
              //         }),
              //       ],
              //     ),
              //   ),
              // ),
              const SizedBox(height: 16),
              // Sección de Administración y Seguridad
              Material(
                color: Colors.transparent,
                elevation: 2,
                child: Container(
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Administración y Seguridad",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.notifications_none_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          "Notificaciones",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          logger.i("Notificaciones seleccionadas");
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.help_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          "Ayuda y Comentarios",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpAndFAQPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          "Acerca de",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
              ),




 const SizedBox(height: 16),







Material(
  elevation: 0,
  borderRadius: BorderRadius.circular(25),
  child: SizedBox(
    width: MediaQuery.sizeOf(context).width,
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
        Icons.logout_sharp, // Usa un ícono más grueso
        color: Colors.white,
        size: 24, // Ajusta el tamaño según tu necesidad
      ),
      label: Text(
        "Cerrar sesión",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              // color: Theme.of(context).colorScheme.onError,
              color: Colors.white,

            ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.blueAccent[700] // Color para modo oscuro
            : Colors.orange, // Color para modo claro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25), // Borde redondeado
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16), // Espaciado interno
        elevation: 0, // Sin sombra
      ),
    ),
  ),
),


 const SizedBox(height: 20),

            ],
          ),
        ),
      );
    },
  );
}



}


ImageProvider<Object> _getProfileImage(String? profilePhoto) {
  if (profilePhoto != null && profilePhoto.isNotEmpty) {
    logger.i('Usando foto del perfil: $profilePhoto');
    return NetworkImage(profilePhoto); 
  }

  logger.w('Usando imagen predeterminada');
  return const AssetImage('assets/default_avatar.png'); 
}