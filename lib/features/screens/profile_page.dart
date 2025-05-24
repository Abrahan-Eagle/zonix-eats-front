import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_eats/features/services/qr_profile_api_service.dart';
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:zonix_eats/features/services/auth/google_sign_in_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zonix_eats/features/utils/auth_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Importa QrImageView
import 'package:zonix_eats/features/DomainProfiles/Profiles/api/profile_service.dart';


final logger = Logger();

class ProfilePage1 extends StatefulWidget {
  const ProfilePage1({super.key});

  @override
  ProfilePage1State createState() => ProfilePage1State();
}

class ProfilePage1State extends State<ProfilePage1> {
  final GoogleSignInService googleSignInService = GoogleSignInService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  GoogleSignInAccount? currentUser;
  bool isAuthenticated = false;
  String? _profileId;


Future<void> _initializeData() async {
  await _checkAuthentication();
  if (isAuthenticated) {
    await _fetchProfileId();
  }
}


  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    isAuthenticated = await AuthUtils.isAuthenticated();
    if (isAuthenticated) {
      currentUser = await GoogleSignInService.getCurrentUser();
      if (currentUser != null) {
        logger.i('Foto de usuario: ${currentUser!.photoUrl}');
        await _storage.write(key: 'userPhotoUrl', value: currentUser!.photoUrl);
        logger.i('Nombre de usuario: ${currentUser!.displayName}');
        await _storage.write(key: 'displayName', value: currentUser!.displayName);
      }
    }
    setState(() {});
  }

  Future<void> _fetchProfileId() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileId = await QrProfileApiService().sendUserIdToBackend(userProvider.userId);

      if (profileId != null) {
        _profileId = profileId; // Asigna directamente el ID de perfil
        await _storage.write(key: 'profileId', value: profileId);
        logger.i('ID de perfil obtenido: $profileId');
      } else {
        logger.e('No se pudo obtener el ID de perfil del backend');
      }
    } catch (e) {
      logger.e('Error al obtener el ID de perfil: $e');
    }
    setState(() {}); // Actualiza la interfaz de usuario
  }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     return Scaffold(
//       body: Column(
//         children: [
//           const Expanded(flex: 2, child: _TopPortion()),
//           Expanded(
//             flex: 3,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   // Nombre del usuario
//                   Text(
//                     userProvider.userName.isNotEmpty
//                         ? userProvider.userName
//                         : (currentUser != null && currentUser!.displayName != null
//                             ? currentUser!.displayName!
//                             : "Usuario"), // Valor predeterminado
//                     style: Theme.of(context)
//                         .textTheme
//                         .titleLarge
//                         ?.copyWith(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   // ID del usuario
//                   Text(
//                     userProvider.userId != null && userProvider.userId.toString().isNotEmpty
//                         ? "ID: ${userProvider.userId}"
//                         : "ID no disponible",
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
//                   ),
//                   const SizedBox(height: 16),
//                   // ID de perfil (si está disponible)
//                   if (_profileId != null)
//                     Column(
//                       children: [
//                         Text(
//                           "Profile ID: $_profileId",
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                         const SizedBox(height: 8),
//                         QrImageView(
//                           data: _profileId!,
//                           size: 200.0,
//                           version: QrVersions.auto,
//                           foregroundColor: Theme.of(context).brightness == Brightness.dark
//                               ? Colors.white // Color blanco si el tema es oscuro
//                               : Colors.black, // Color negro si el tema es claro
//                           backgroundColor: Colors.transparent,
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// class _TopPortion extends StatefulWidget {
//   const _TopPortion({Key? key}) : super(key: key);

//   @override
//   _TopPortionState createState() => _TopPortionState();
// }

// class _TopPortionState extends State<_TopPortion> {
//   dynamic _profile;
//   GoogleSignInAccount? currentUser;

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }

//   Future<void> _initializeData() async {
//     final userProvider = Provider.of<UserProvider>(context, listen: false);
//     currentUser = await GoogleSignInService.getCurrentUser();

//     try {
//       // Obtén el perfil
//       _profile = await ProfileService().getProfileById(userProvider.userId);
//       setState(() {});  // Actualiza la UI una vez que se haya cargado el perfil
//     } catch (e) {
//       logger.e('Error al obtener el perfil: $e');
//       setState(() {});  // Si hay error, aún actualizar la UI
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         Container(
//           margin: const EdgeInsets.only(bottom: 50),
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.bottomCenter,
//               end: Alignment.topCenter,
//               colors: [Color(0xff0043ba), Color(0xff006df1)],
//             ),
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(50),
//               bottomRight: Radius.circular(50),
//             ),
//           ),
//         ),
//         Align(
//           alignment: Alignment.bottomCenter,
//           child: SizedBox(
//             width: 150,
//             height: 150,
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     shape: BoxShape.circle,
//                     image: DecorationImage(
//                       fit: BoxFit.cover,
//                       image: _getProfileImage(_profile?.photo, currentUser?.photoUrl),
//                     ),
//                   ),
//                 ),





//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: CircleAvatar(
//                     radius: 20,
//                     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//                     child: Container(
//                       margin: const EdgeInsets.all(8.0),
//                       decoration: const BoxDecoration(
//                         color: Colors.green,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }


//   ImageProvider<Object> _getProfileImage(String? profilePhoto, String? googlePhotoUrl) {
//   if (profilePhoto != null && profilePhoto.isNotEmpty) {
//     logger.i('Usando foto del perfil: $profilePhoto');
//     // Usando FadeInImage con la imagen de perfil
//     return NetworkImage(profilePhoto); // Este sigue siendo un ImageProvider
//   }
  
//   if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
//     logger.i('Usando foto de Google: $googlePhotoUrl');
//     // Usando FadeInImage con la foto de Google
//     return NetworkImage(googlePhotoUrl); // Este sigue siendo un ImageProvider
//   }

//   logger.w('Usando imagen predeterminada');
//   return const AssetImage('assets/default_avatar.png');
// }

@override
Widget build(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context);
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Reemplazo de FlutterFlowTheme
    appBar: AppBar(
      backgroundColor: const Color(0xFF4B39EF),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Mi Código QR',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      elevation: 2,
    ),
    body: Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              userProvider.userName.isNotEmpty
                  ? userProvider.userName
                  : (currentUser != null && currentUser!.displayName != null
                  ? currentUser!.displayName!
                  : "Usuario"), // Valor predeterminado
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
            ),


            const SizedBox(height: 4),
            Text(
              userProvider.userEmail != null
                  ? "Email: ${userProvider.userEmail}" // Asegurar que es String
                  : "Email no disponible",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Material(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: QrImageView(
                    data: userProvider.userId.toString(),// Asegurar que es String
                    size: 250.0,
                    version: QrVersions.auto,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Material(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow("Google ID", userProvider.userGoogleId.toString()),

                    const SizedBox(height: 12),
                    _infoRow("Última actualización", "Hoy 10:30 AM"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _infoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}


}

