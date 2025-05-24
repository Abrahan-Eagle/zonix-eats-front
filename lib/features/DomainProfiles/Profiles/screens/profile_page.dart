import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de agregar esta dependencia en pubspec.yaml
import 'package:zonix_eats/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/screens/edit_profile_page.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/screens/create_profile_page.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/screens/select_station_modal.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

final logger = Logger();

class ProfileModel with ChangeNotifier {
  Profile? _profile;
  bool _isLoading = true;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> loadProfile(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await ProfileService().getProfileById(userId);
    } catch (e) {
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateProfile(Profile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}

class ProfilePagex extends StatelessWidget {
  final int userId;
  final bool statusId;

  const ProfilePagex({super.key, required this.userId, this.statusId = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileModel()..loadProfile(userId),
      child: Consumer<ProfileModel>(
        builder: (context, profileModel, child) {
          if (profileModel.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Perfil')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Si no hay perfil, redirige a la página de creación de perfil
          if (profileModel.profile == null) {
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateProfilePage(userId: userId),
                ),
              );
            });
            return const SizedBox(); // Retorna un widget vacío mientras se redirige
          }

        
              return Scaffold(
                body: Stack(
                  children: [
                    Column(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: _TopPortion(),
                        ), // Encabezado visual
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: _buildProfileDetails(context, profileModel.profile!),
                          ),
                        ),
                      ],
                    ),
                    if (statusId)
                      Positioned(
                        right: 10,
                        top: 215, // Ajusta esta posición según sea necesario
                        child: FloatingActionButton(
                          onPressed: () async {
                            // Mostrar modal con select
                            showDialog(
                              context: context,
                              builder: (context) {
                                return SelectStationModal(userId: userId);
                              },
                            );
                          },
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.check),
                        ),
                      ),
                  ],
                ),
              );




        },
      ),
    );
  }


  

  String translateMaritalStatus(String status) {
    switch (status) {
      case 'single':
        return 'Soltero';
      case 'married':
        return 'Casado';
      case 'divorced':
        return 'Divorciado';
      default:
        return 'N/A';
    }
  }

  Widget _buildProfileDetails(BuildContext context, Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileField('Nombre', profile.firstName),
        if (profile.middleName != null && profile.middleName!.isNotEmpty)
          _buildProfileField('Segundo Nombre', profile.middleName!),
        _buildProfileField('Apellido', profile.lastName),
        if (profile.secondLastName != null &&
            profile.secondLastName!.isNotEmpty)
          _buildProfileField('Segundo Apellido', profile.secondLastName!),
        // _buildProfileField('Fecha de Nacimiento', profile.dateOfBirth ?? 'N/A'),
        _buildProfileField(
          'Fecha de Nacimiento',
          _formatDate(profile.dateOfBirth), // Usamos la función que formatea la fecha
        ),
        _buildProfileField(
          'Estado Civil',
          translateMaritalStatus(profile.maritalStatus ?? 'N/A'),
        ),
        _buildProfileField('Sexo', profile.sex),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              onPressed: () => _navigateToEditOrCreatePage(context, profile),
              label: const Text('Editar Perfil'),
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }


  // Función para formatear la fecha en 'dd-MM-yyyy'
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'N/A';  // Si no hay fecha, devuelve 'N/A'
    }
    
    final DateFormat format = DateFormat('dd-MM-yyyy');  // El formato deseado
    try {
      final DateTime parsedDate = DateTime.parse(date);  // Convierte la fecha a DateTime
      return format.format(parsedDate);  // Formatea la fecha
    } catch (e) {
      return 'N/A';  // En caso de error, devuelve 'N/A'
    }
  }

  void _navigateToEditOrCreatePage(BuildContext context, Profile profile) {
    final route =
        profile == null
            ? MaterialPageRoute(
              builder: (context) => CreateProfilePage(userId: profile.userId),
            )
            : MaterialPageRoute(
              builder: (context) => EditProfilePage(userId: profile.userId),
            );

    Navigator.push(context, route).then((_) {
      // Carga nuevamente el perfil después de editar o crear
      Provider.of<ProfileModel>(
        context,
        listen: false,
      ).loadProfile(profile.userId);
    });
  }

  Widget _buildProfileField(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Espacio lateral
              alignment: Alignment.centerLeft,
              child: Text(
                '$etiqueta:',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Espacio lateral
              alignment: Alignment.centerRight,
              child: Text(
                valor,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPortion extends StatelessWidget {
  const _TopPortion();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 145),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xff0043ba), Color(0xff006df1)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.4),
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 6),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    backgroundImage: _buildProfileImage(context),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider<Object>? _buildProfileImage(BuildContext context) {
    final profile = context.read<ProfileModel>().profile;
    if (profile?.photo != null) {
      return NetworkImage(profile!.photo!);
    }
    return const AssetImage('assets/default_avatar.png');
  }
}
