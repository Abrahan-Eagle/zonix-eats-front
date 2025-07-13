import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static final storage = const FlutterSecureStorage();
  
  // Token de prueba temporal para desarrollo
  static const String _testToken = '4|mfQNidd6dzR91KyVVDaQLWrK0THNGUw0muz4WEgu609f1add';

  static Future<Map<String, String>> getAuthHeaders() async {
    // Token temporal para desarrollo - reemplazar con autenticación real
    const String tempToken = '2|vzuY1CyKpnzApz8uemUegZhbZQK2tBVcNNZcWkbg71802543';
    
    return {
      'Authorization': 'Bearer $tempToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
}
