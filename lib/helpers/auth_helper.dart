import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static final storage = const FlutterSecureStorage();
  
  static Future<Map<String, String>> getAuthHeaders() async {
    try {
      // Obtener el token real del storage
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        throw Exception('Token no encontrado. El usuario no está autenticado.');
      }
      
      return {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      throw Exception('Error al obtener headers de autenticación: $e');
    }
  }
}
