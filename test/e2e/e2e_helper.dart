import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zonix/config/app_config.dart';

/// Helper class para tests E2E
/// Proporciona métodos para autenticación y creación de datos de prueba
class E2EHelper {
  static final String baseUrl = AppConfig.apiUrl;

  /// Verificar que el backend está disponible
  static Future<bool> checkBackendHealth() async {
    try {
      // Usar el endpoint /api/ping que está disponible públicamente
      final response = await http.get(
        Uri.parse('$baseUrl/api/ping'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] != null;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Crear usuario de prueba (requiere endpoint de registro o seeder)
  static Future<Map<String, dynamic>?> createTestUser({
    required String email,
    required String password,
    required String role,
    String? name,
  }) async {
    try {
      // Nota: Esto requiere un endpoint de registro o usar seeders del backend
      // Por ahora, retornamos null y asumimos que los usuarios ya existen
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Autenticarse y obtener token
  static Future<String?> authenticate({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] ?? data['data']?['token'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener headers de autenticación
  static Map<String, String> getAuthHeaders(String? token) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// Crear orden de prueba
  static Future<Map<String, dynamic>?> createTestOrder({
    required String? token,
    required int commerceId,
    required int productId,
    int quantity = 2,
    double total = 50.00,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/orders'),
        headers: getAuthHeaders(token),
        body: jsonEncode({
          'products': [
            {
              'id': productId,
              'quantity': quantity,
            }
          ],
          'commerce_id': commerceId,
          'delivery_type': 'delivery',
          'total': total,
          'delivery_address': 'Calle de Prueba E2E 123',
          'notes': 'Orden de prueba E2E',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Limpiar datos de prueba (opcional)
  static Future<void> cleanupTestData({
    int? orderId,
    String? token,
  }) async {
    // Implementar limpieza si es necesario
    // Por ejemplo, eliminar órdenes de prueba creadas
  }
}
