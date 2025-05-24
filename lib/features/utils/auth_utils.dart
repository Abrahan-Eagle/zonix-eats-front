import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix_eats/features/services/auth/api_service.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();
final ApiService _apiService = ApiService();

class AuthUtils {
  // Método para verificar si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    final expiryDateStr = await getExpiryDate();

    if (token != null && expiryDateStr != null) {
      final expiryDate = DateTime.parse(expiryDateStr);
      if (DateTime.now().isBefore(expiryDate)) {
        return true; // El token es válido
      } else {
        await _storage.deleteAll(); // Eliminar token si ha expirado
      }
    }
    return false; // No hay token o ha expirado
  }

  // Método para guardar el token y la fecha de expiración
  static Future<void> saveToken(String token, int expiresIn) async {
    await _storage.write(key: 'token', value: token);
    final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));
    await _storage.write(key: 'expiryDate', value: expiryDate.toIso8601String());
  }

  // Método para obtener el token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // Método para obtener la fecha de expiración
  static Future<String?> getExpiryDate() async {
    return await _storage.read(key: 'expiryDate');
  }

  // Método para eliminar todos los tokens
  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // Maneja el cierre de sesión
  static Future<void> logout() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        final response = await _apiService.logout(token);
        if (response.statusCode == 200) {
          await _storage.deleteAll();
          logger.i('Sesión cerrada correctamente');
        } else {
          logger.e('Error: ${response.statusCode}');
          throw Exception('Error en la API al cerrar sesión');
        }
      }
    } catch (e) {
      logger.e('Error al cerrar sesión: $e');
    }
  }

  // Método para guardar el userId como String
  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: 'userId', value: userId.toString()); // Convertir a String
  }

 static Future<void> saveUserGoogleId(String userGoogleId) async {
    await _storage.write(key: 'userGoogleId', value: userGoogleId);
  }


  // Método para obtener el userId como int
  static Future<int?> getUserId() async {
    final userIdStr = await _storage.read(key: 'userId');
    if (userIdStr != null) {
      return int.tryParse(userIdStr); // Convertir a int
    }
    return null; // Retorna null si no se encuentra o no es un número válido
  }



  static Future<String?> getUserGoogleId() async {
    return await _storage.read(key: 'userGoogleId');
  }

  

  // Métodos para guardar y obtener el nombre de usuario
  static Future<void> saveUserName(String userName) async {
    await _storage.write(key: 'userName', value: userName);
  }

  static Future<void> saveUserRole(String userRole) async {
    await _storage.write(key: 'role', value: userRole);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: 'userName');
  }

  // Métodos para guardar y obtener el correo electrónico del usuario
  static Future<void> saveUserEmail(String userEmail) async {
    await _storage.write(key: 'userEmail', value: userEmail);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: 'userEmail');
  }

  // Métodos para guardar y obtener la URL de la foto del usuario
  static Future<void> saveUserPhotoUrl(String photoUrl) async {
    await _storage.write(key: 'userPhotoUrl', value: photoUrl);
  }

  static Future<String?> getUserPhotoUrl() async {
    return await _storage.read(key: 'userPhotoUrl');
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'role');
  }
}
