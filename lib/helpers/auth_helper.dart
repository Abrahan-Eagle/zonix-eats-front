import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static const storage = FlutterSecureStorage();
  
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
      // Si hay error de encriptación (BAD_DECRYPT), limpiar almacenamiento
      if (e.toString().contains('BAD_DECRYPT') || e.toString().contains('BadPaddingException')) {
        try {
          await storage.deleteAll();
        } catch (_) {
          // Ignorar errores al limpiar
        }
      }
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    try {
      return await storage.read(key: 'token');
    } catch (e) {
      // Si hay error de encriptación (BAD_DECRYPT), limpiar almacenamiento
      if (e.toString().contains('BAD_DECRYPT') || e.toString().contains('BadPaddingException')) {
        try {
          await storage.deleteAll();
        } catch (_) {
          // Ignorar errores al limpiar
        }
      }
      return null;
    }
  }
}
