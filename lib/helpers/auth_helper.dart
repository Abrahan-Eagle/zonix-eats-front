import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static final storage = const FlutterSecureStorage();
  
  // Token de prueba temporal para desarrollo
  static const String _testToken = '4|mfQNidd6dzR91KyVVDaQLWrK0THNGUw0muz4WEgu609f1add';

  static Future<Map<String, String>> getAuthHeaders() async {
    String? token = await storage.read(key: 'token');
    
    // Si no hay token guardado, usar el token de prueba
    if (token == null) {
      token = _testToken;
      // Guardar el token de prueba para futuras peticiones
      await storage.write(key: 'token', value: token);
    }
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
