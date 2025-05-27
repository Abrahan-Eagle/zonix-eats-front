import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/qr_profile_api_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/services/auth/google_sign_in_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Importa QrImageView
// import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';


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

