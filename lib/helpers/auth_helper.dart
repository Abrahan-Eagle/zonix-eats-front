import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static final storage = const FlutterSecureStorage();

  static Future<Map<String, String>> getAuthHeaders() async {
    String? token = await storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
