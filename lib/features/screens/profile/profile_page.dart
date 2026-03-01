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
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix/features/utils/app_colors.dart';


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
  late Future<Profile?> _profileFuture;

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _profileFuture = ProfileService().getProfileById(userProvider.userId);
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Scaffold(
    backgroundColor: AppColors.scaffoldBg(context),
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.headerGradientStart(context),
              AppColors.headerGradientMid(context),
              AppColors.headerGradientEnd(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Mi Perfil', // TODO: internacionalizar
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          elevation: 0,
        ),
      ),
    ),
    body: FutureBuilder<Profile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('Error: \\${snapshot.error}', style: TextStyle(color: AppColors.error(context))),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    setState(() {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      _profileFuture = ProfileService().getProfileById(userProvider.userId);
                    });
                  },
                  child: const Text('Reintentar'), // TODO: internacionalizar
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No se encontró el perfil', style: TextStyle(color: AppColors.secondaryText(context)))); // TODO: internacionalizar
        }
        final profile = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Card(
              color: AppColors.cardBg(context),
              elevation: 8,
              shadowColor: AppColors.purple.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (profile.photo != null && profile.photo!.isNotEmpty)
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(profile.photo!),
                        backgroundColor: AppColors.purple.withValues(alpha: 0.15),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      profile.firstName + ' ' + profile.lastName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: \\${profile.id}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText(context)),
                    ),
                    const SizedBox(height: 24),
                    _infoRow('Fecha de nacimiento', profile.dateOfBirth, context),
                    _infoRow('Estado civil', profile.maritalStatus, context),
                    _infoRow('Sexo', profile.sex, context),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentButton(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        // Acción de editar perfil o compartir QR
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Editar perfil', style: TextStyle(color: Colors.white)), // TODO: internacionalizar
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _infoRow(String label, String value, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.secondaryText(context))),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText(context))),
      ],
    ),
  );
}


}

