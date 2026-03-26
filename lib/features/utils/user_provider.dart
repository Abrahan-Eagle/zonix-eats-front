import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zonix/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_service.dart';

final logger = Logger();
const FlutterSecureStorage _storage = FlutterSecureStorage();

/// Token rechazado por `/api/auth/user` (401): sesión local ya sincronizada en catch de [checkAuthentication].
class SessionRejectedByApiException implements Exception {
  const SessionRejectedByApiException();
  @override
  String toString() => 'SessionRejectedByApiException';
}

/// Estado del usuario autenticado.
///
/// En backend: [users] es la cuenta (auth, email, rol). [profiles] es la extensión 1:1
/// del usuario (el perfil de la persona). Phones, documents y addresses pertenecen
/// al perfil (profile_id), no directamente a users.
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
  int _profileId = 0;
  String _userGoogleId = '';
  String _role = '';
  bool _completedOnboarding = false;

  // Caché para evitar múltiples llamadas simultáneas
  Future<Map<String, dynamic>>? _getUserDetailsFuture;
  Map<String, dynamic>? _cachedUserDetails;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 1); // Cache válido por 1 minuto

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
  /// ID del perfil (tabla profiles). Relación 1:1 con users: el perfil es la extensión de la persona.
  /// Phones, documents y addresses están ligados al perfil. Las APIs usan user_id en la URL y el backend resuelve el perfil.
  int get profileId => _profileId;
  String get userGoogleId => _userGoogleId;
  String get userRole => _role;
  bool get completedOnboarding => _completedOnboarding;

  // Getter para obtener el usuario completo
  Map<String, dynamic> get user => {
    'id': _userId,
    'profile_id': _profileId,
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

  void setCompletedOnboarding(bool value) {
    _completedOnboarding = value;
    _storage.write(key: 'userCompletedOnboarding', value: value ? '1' : '0');
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
        await _initRealtimeServices();
      }
    } catch (e) {
      _isAuthenticated = false;
      if (e is SessionRejectedByApiException) {
        // Limpieza ya hecha en [getUserDetails] (token + estado + Pusher).
        logger.i('Sesión rechazada por el servidor (401). Inicia sesión de nuevo.');
      } else {
        debugPrint('Error al verificar autenticación: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _initRealtimeServices() async {
    if (_userId <= 0) return;
    PusherService.instance.subscribeToUserChannel(_userId);
    await _registerFcmToken();
    // Reintento por si el token FCM llegó después del login (permiso notificaciones)
    Future.delayed(const Duration(seconds: 3), () => _registerFcmToken());

    if (_role == 'commerce') {
      try {
        final data = await CommerceDataService.getCommerceData();
        final commerceId = data['id'] is int
            ? data['id'] as int
            : int.tryParse(data['id']?.toString() ?? '0') ?? 0;
        if (commerceId > 0) {
          PusherService.instance.subscribeToCommerceChannel(commerceId);
        }
      } catch (e) {
        logger.w('Could not subscribe to commerce channel: $e');
      }
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      // El backend asocia FCM al perfil; sin profile_id aún (p. ej. antes de onboarding) no enviamos.
      if (_profileId <= 0) {
        return;
      }
      // Obtener auth token usando AuthUtils (mismo storage donde el login guarda)
      var token = await AuthUtils.getToken();
      token ??= await _storage.read(key: 'token');
      final fcmToken = await _storage.read(key: 'fcm_token');
      if (token == null || token.isEmpty) {
        logger.w('FCM: no se registra (falta token de sesión)');
        return;
      }
      if (fcmToken == null || fcmToken.isEmpty) {
        logger.w('FCM: no se registra (falta fcm_token; acepta notificaciones al abrir la app)');
        return;
      }

      logger.i('FCM: registrando token en backend...');
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/chat/fcm/register'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'device_token': fcmToken}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.i('FCM token registrado en backend (push activo)');
      } else {
        logger.w('FCM registro falló: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      logger.w('FCM token registration failed: $e');
    }
  }

  /// Tras crear el perfil en onboarding: sincroniza `/api/auth/user` y registra el token FCM en el backend.
  Future<void> registerFcmTokenAfterProfileReady() async {
    try {
      await getUserDetails(forceRefresh: true);
      await _loadUserData();
      await _registerFcmToken();
      Future.delayed(const Duration(seconds: 2), () => _registerFcmToken());
    } catch (e) {
      logger.w('registerFcmTokenAfterProfileReady: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      _userName = await AuthUtils.getUserName() ?? '';
      _userEmail = await AuthUtils.getUserEmail() ?? '';
      _userPhotoUrl = await AuthUtils.getUserPhotoUrl() ?? '';
      _role = await AuthUtils.getUserRole() ?? '';
      _userId = await AuthUtils.getUserId() ?? 0;
      _profileId = await AuthUtils.getProfileId() ?? 0;
      _userGoogleId = await AuthUtils.getUserGoogleId() ?? '';
      _completedOnboarding = (await _storage.read(key: 'userCompletedOnboarding')) == '1';
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

  Future<Map<String, dynamic>> getUserDetails({bool forceRefresh = false}) async {
    // Si hay un request en progreso, devolver ese mismo Future para evitar múltiples llamadas
    if (_getUserDetailsFuture != null && !forceRefresh) {
      return _getUserDetailsFuture!;
    }
    
    // Si hay caché válido y no se fuerza refresh, devolver caché
    if (_cachedUserDetails != null && 
        _cacheTimestamp != null && 
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration &&
        !forceRefresh) {
      logger.i('Returning cached user details');
      return _cachedUserDetails!;
    }
    
    // Crear nuevo Future para la llamada
    _getUserDetailsFuture = _fetchUserDetails();

    try {
      final result = await _getUserDetailsFuture!;
      _cachedUserDetails = result;
      _cacheTimestamp = DateTime.now();
      return result;
    } on SessionRejectedByApiException {
      // Misma sesión inválida que en [checkAuthentication]; fuerza vuelta al login vía Consumer<MyApp>.
      try {
        PusherService.instance.disconnect();
      } catch (_) {}
      await _clearUserData();
      notifyListeners();
      rethrow;
    } finally {
      _getUserDetailsFuture = null;
    }
  }
  
  Future<Map<String, dynamic>> _fetchUserDetails() async {
    try {
      // Usar AuthUtils.getToken() para coincidir con donde el login guarda el token
      var token = await AuthUtils.getToken();
      if (token == null || token.isEmpty) {
        token = await _storage.read(key: 'token');
      }
      if (token == null || token.isEmpty) {
        throw const SessionRejectedByApiException();
      }

      logger.i('Token de sesión presente (longitud: ${token.length})');
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/auth/user'),
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
        _profileId = userDetails['profile_id'] ?? 0;
        _role = userDetails['role'] ?? '';
        _completedOnboarding = userDetails['completed_onboarding'] == 1 ||
            userDetails['completed_onboarding'] == true ||
            userDetails['completed_onboarding']?.toString() == '1';

        // Persistir para que _loadUserData no sobrescriba con valores ausentes
        await AuthUtils.saveUserId(_userId);
        await AuthUtils.saveProfileId(_profileId);
        await AuthUtils.saveUserRole(_role);
        await _storage.write(key: 'userCompletedOnboarding', value: _completedOnboarding ? '1' : '0');

        logger.i('User details loaded (id: ${userDetails['id']}, role: $_role)');
        return {
          'users': userDetails,
          'role': _role,
          'userId': _userId,
          'profileId': _profileId,
          'userGoogleId': _userGoogleId,
        };
      } else if (response.statusCode == 401) {
        // Token caducado/revocado en servidor pero fecha local aún "válida" (p. ej. migrate:fresh, logout remoto).
        logger.w('GET /api/auth/user → 401; limpiando token Sanctum local');
        await AuthUtils.invalidateSanctumSession();
        _cachedUserDetails = null;
        _cacheTimestamp = null;
        throw const SessionRejectedByApiException();
      } else if (response.statusCode == 429) {
        // Rate limiting: esperar un poco y usar caché si está disponible
        logger.w('Rate limit exceeded (429), using cache if available');
        if (_cachedUserDetails != null) {
          return _cachedUserDetails!;
        }
        logger.e('Error: ${response.statusCode} - Rate limit exceeded');
        throw Exception('Demasiadas solicitudes. Por favor, espera un momento.');
      } else {
        logger.e('Error al obtener detalles del usuario: ${response.statusCode}');
        throw Exception('Error al obtener detalles del usuario');
      }
    } catch (e) {
      if (e is SessionRejectedByApiException) {
        rethrow;
      }
      logger.e('Exception: $e');
      // Si hay error y tenemos caché, devolver caché
      if (_cachedUserDetails != null && !(e is Exception && e.toString().contains('Token no encontrado'))) {
        logger.w('Error fetching user details, returning cached data');
        return _cachedUserDetails!;
      }
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
    final token = await AuthUtils.getToken();
    try {
      PusherService.instance.disconnect();
    } catch (_) {}
    await _clearUserData();
    notifyListeners();
    try {
      if (token != null && token.isNotEmpty) {
        await _unregisterFcmTokenWithToken(token);
      }
      await AuthUtils.logout();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  /// Token inválido o BD reiniciada (p. ej. migrate:fresh): limpia sesión local sin llamar logout API.
  Future<void> invalidateSessionLocally() async {
    try {
      PusherService.instance.disconnect();
    } catch (_) {}
    try {
      await AuthUtils.clearTokens();
    } catch (_) {}
    await _clearUserData();
    notifyListeners();
  }

  /// Llama al backend para eliminar el token FCM del perfil (dejar de recibir push en este dispositivo).
  Future<void> _unregisterFcmTokenWithToken(String token) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/chat/fcm/unregister'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      logger.i('FCM token desregistrado');
    } catch (e) {
      logger.w('FCM unregister failed: $e');
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
    _profileId = 0;
    _userGoogleId = '';
    _role = '';
    
    // Limpiar caché
    _cachedUserDetails = null;
    _cacheTimestamp = null;
    _getUserDetailsFuture = null;

    // Limpia en el almacenamiento seguro
    await _storage.delete(key: 'profileCreated');
    await _storage.delete(key: 'adresseCreated');
    await _storage.delete(key: 'documentCreated');
    await _storage.delete(key: 'gasCylindersCreated');
    await _storage.delete(key: 'phoneCreated');
    await _storage.delete(key: 'emailCreated');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'expiryDate');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'fcm_token');
  }

  // Bypass de login para tests de integración
  void setAuthenticatedForTest({String role = 'commerce'}) {
    _isAuthenticated = true;
    _role = role;
    _userId = 9999;
    _userName = 'Test Commerce';
    _userEmail = 'test@commerce.com';
    _userPhotoUrl = '';
    notifyListeners();
  }
}

/// Si [DeliveryService] detectó 401/403 o token inválido, limpia [UserProvider] y muestra aviso.
Future<void> syncDeliverySessionAfterApi(BuildContext context, DeliveryService delivery) async {
  if (!delivery.consumeSessionInvalidated()) return;
  if (!context.mounted) return;
  await context.read<UserProvider>().invalidateSessionLocally();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Tu sesión expiró o el servidor reinició los datos. Vuelve a iniciar sesión.',
      ),
    ),
  );
}
