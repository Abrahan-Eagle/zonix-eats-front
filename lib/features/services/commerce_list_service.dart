import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'package:zonix/models/my_commerce.dart';

/// Servicio para listar y gestionar los restaurantes del usuario commerce (multi-restaurante).
class CommerceListService {
  static String get baseUrl => AppConfig.apiUrl;

  /// Listar todos los comercios del perfil
  static Future<List<MyCommerce>> getMyCommerces() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/commerce/commerces'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => MyCommerce.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    }
    throw Exception('Error al obtener restaurantes: ${response.statusCode}');
  }

  /// Crear un nuevo comercio/restaurante
  static Future<MyCommerce> createCommerce({
    required String businessName,
    required String businessType,
    required String taxId,
    required String address,
    bool open = false,
    String? schedule,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final body = {
      'business_name': businessName,
      'business_type': businessType,
      'tax_id': taxId,
      'address': address,
      'open': open,
      if (schedule != null) 'schedule': schedule,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/commerce/commerces'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return MyCommerce.fromJson(Map<String, dynamic>.from(data['data']));
      }
    }
    throw Exception('Error al crear restaurante: ${response.statusCode}');
  }

  /// Establecer un comercio como principal (selector activo)
  static Future<void> setPrimary(int commerceId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/api/commerce/commerces/$commerceId/set-primary'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cambiar restaurante principal: ${response.statusCode}');
    }
  }
}
