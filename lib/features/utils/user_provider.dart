import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import 'package:http/http.dart' as http;

final logger = Logger();
const FlutterSecureStorage _storage = FlutterSecureStorage();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class UserProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _profileCreated = false;
  bool _adresseCreated = false;
  bool _documentCreated = false;
  bool _gasCylindersCreated = false;
  bool _phoneCreated = false;
  bool _emailCreated = false;

  String _userName = '';
  String _userEmail = '';
  String _userPhotoUrl = '';
  int _userId = 0;
  String _userGoogleId = '';
  String _role = '';

  // Getters para obtener la información del usuario
  bool get isAuthenticated => _isAuthenticated;
  bool get profileCreated => _profileCreated;
  bool get adresseCreated => _adresseCreated;
  bool get documentCreated => _documentCreated;
  bool get gasCylindersCreated => _gasCylindersCreated;
  bool get phoneCreated => _phoneCreated;
  bool get emailCreated => _emailCreated;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhotoUrl => _userPhotoUrl;
  int get userId => _userId;
  String get userGoogleId => _userGoogleId;
  String get userRole => _role;
  
  // Getter para obtener el usuario completo
  Map<String, dynamic> get user => {
    'id': _userId,
    'name': _userName,
    'email': _userEmail,
    'photo_url': _userPhotoUrl,
    'google_id': _userGoogleId,
    'role': _role,
  };

  // Setter para actualizar el estado de creación de perfil
  void setProfileCreated(bool value) {
    _profileCreated = value;
    _storage.write(key: 'profileCreated', value: value.toString());
    notifyListeners();
  }

  void setAdresseCreated(bool value) {
    _adresseCreated = value;
    _storage.write(key: 'adresseCreated', value: value.toString());
    notifyListeners();
  }

  void setDocumentCreated(bool value) {
    _documentCreated = value;
    _storage.write(key: 'documentCreated', value: value.toString());
    notifyListeners();
  }

  void setGasCylindersCreated(bool value) {
    _gasCylindersCreated = value;
    _storage.write(key: 'gasCylindersCreated', value: value.toString());
    notifyListeners();
  }

  void setPhoneCreated(bool value) {
    _phoneCreated = value;
    _storage.write(key: 'phoneCreated', value: value.toString());
    notifyListeners();
  }

  void setEmailCreated(bool value) {
    _emailCreated = value;
    _storage.write(key: 'emailCreated', value: value.toString());
    notifyListeners();
  }

  // Verifica si el usuario está autenticado y carga los datos si es necesario
  Future<void> checkAuthentication() async {
    try {
      _isAuthenticated = await AuthUtils.isAuthenticated();
      if (_isAuthenticated) {
        await getUserDetails();
        await _loadUserData();
        logger.i('Final userId: $_userId');
      }
    } catch (e) {
      debugPrint('Error al verificar autenticación: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    try {
      _userName = await AuthUtils.getUserName() ?? '';
      _userEmail = await AuthUtils.getUserEmail() ?? '';
      _userPhotoUrl = await AuthUtils.getUserPhotoUrl() ?? '';
      _role = await AuthUtils.getUserRole() ?? '';
      _userId = await AuthUtils.getUserId() ?? 0;
      _userGoogleId = await AuthUtils.getUserGoogleId() ?? '';
      _profileCreated = (await _storage.read(key: 'profileCreated')) == 'true';
      _adresseCreated = (await _storage.read(key: 'adresseCreated')) == 'true';
      _documentCreated = (await _storage.read(key: 'documentCreated')) == 'true';
      _gasCylindersCreated = (await _storage.read(key: 'gasCylindersCreated')) == 'true';
      _phoneCreated = (await _storage.read(key: 'phoneCreated')) == 'true';
      _emailCreated = (await _storage.read(key: 'emailCreated')) == 'true';
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado. El usuario no está autenticado.');
      }

      logger.i('Retrieved token: $token');
      final response = await http.get(
        // Uri.parse('${AppConfig.baseUrl}/api/auth/user'),
        Uri.parse('$baseUrl/api/auth/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Manejar el formato de respuesta del backend {success: true, data: {...}}
        Map<String, dynamic> userDetails;
        if (responseData.containsKey('success') && responseData.containsKey('data')) {
          if (responseData['success'] == true) {
            userDetails = responseData['data'];
          } else {
            throw Exception(responseData['message'] ?? 'Error al obtener detalles del usuario');
          }
        } else {
          // Fallback para respuestas sin formato estándar
          userDetails = responseData;
        }
        
        _userGoogleId = userDetails['google_id'] ?? '';
        _userId = userDetails['id'] ?? 0;
        _role = userDetails['role'] ?? '';
        
        logger.i('User details: $userDetails');
        logger.i('User role: $_role');
        return {
          'users': userDetails, 
          'role': _role, 
          'userId': _userId, 
          'userGoogleId': _userGoogleId
        };
      } else {
        logger.e('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener detalles del usuario');
      }
    } catch (e) {
      logger.e('Exception: $e');
      rethrow;
    }
  }

  // Guarda los datos del usuario autenticado y actualiza el estado
  Future<void> setUserData(GoogleSignInAccount googleUser) async {
    try {
      _updateUserInfo(
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl ?? '',
      );

      await AuthUtils.saveUserName(_userName);
      await AuthUtils.saveUserEmail(_userEmail);
      await AuthUtils.saveUserPhotoUrl(_userPhotoUrl);
      await AuthUtils.saveUserId(_userId);
      await AuthUtils.saveUserGoogleId(_userGoogleId);

      _isAuthenticated = true;
    } catch (e) {
      debugPrint('Error al guardar datos del usuario: $e');
    } finally {
      notifyListeners();
    }
  }

  // Actualiza la información del usuario en memoria
  void _updateUserInfo({required String name, required String email, required String photoUrl}) {
    _userName = name;
    _userEmail = email;
    _userPhotoUrl = photoUrl;
  }

  Future<void> logout() async {
    try {
      await AuthUtils.logout();
      await GoogleSignIn().signOut();
      await _clearUserData();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    } finally {
      notifyListeners();
    }
  }

  // Limpia la información del usuario
  Future<void> _clearUserData() async {
    _isAuthenticated = false;
    _profileCreated = false;
    _adresseCreated = false;
    _documentCreated = false;
    _gasCylindersCreated = false;
    _phoneCreated = false;
    _emailCreated = false;
    _userName = '';
    _userEmail = '';
    _userPhotoUrl = '';
    _userId = 0;
    _userGoogleId = '';

    // Limpia en el almacenamiento seguro
    await _storage.delete(key: 'profileCreated');
    await _storage.delete(key: 'adresseCreated');
    await _storage.delete(key: 'documentCreated');
    await _storage.delete(key: 'gasCylindersCreated');
    await _storage.delete(key: 'phoneCreated');
    await _storage.delete(key: 'emailCreated');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'userId');
  }
}
