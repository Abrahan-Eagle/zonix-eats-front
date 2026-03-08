import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/helpers/auth_helper.dart';
import '../models/phone.dart';

final logger = Logger();

class PhoneService {
  /// Lista los teléfonos del usuario autenticado (GET /api/phones/).
  /// Opcional: [context], [commerceId], [deliveryCompanyId] para filtrar.
  Future<List<Phone>> fetchMyPhones({
    String? context,
    int? commerceId,
    int? deliveryCompanyId,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final query = <String, String>{};
      if (context != null && context.isNotEmpty) query['context'] = context;
      if (commerceId != null) query['commerce_id'] = commerceId.toString();
      if (deliveryCompanyId != null) query['delivery_company_id'] = deliveryCompanyId.toString();
      final uri = Uri.parse('${AppConfig.apiUrl}/api/phones').replace(queryParameters: query.isNotEmpty ? query : null);
      logger.i('Fetching my phones (index)');
      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final success = body['success'] == true;
        final data = body['data'];
        if (success && data != null) {
          final list = data is List ? data : (data is List<dynamic> ? data : []);
          final phones = list.map((e) => Phone.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          logger.i('Fetched ${phones.length} phones');
          return phones;
        }
        if (response.statusCode == 404 || body['message']?.toString().contains('Perfil') == true) {
          return [];
        }
      }
      if (response.statusCode == 404) return [];
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map ? (decoded['message'] ?? response.body).toString() : response.body;
      throw Exception('Error al obtener teléfonos: $msg');
    } catch (e) {
      logger.e('Exception fetching phones: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  /// Lista los teléfonos de un usuario por su user_id (GET /api/phones/by-user/{userId}).
  Future<List<Phone>> fetchPhonesByUserId(int userId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      logger.i('Fetching phones for user: $userId');
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiUrl}/api/phones/by-user/$userId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final list = body['data'] as List;
          final phones = list.map((e) => Phone.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          logger.i('Fetched ${phones.length} phones');
          return phones;
        }
      }
      if (response.statusCode == 403 || response.statusCode == 404) return [];
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map ? (decoded['message'] ?? response.body).toString() : response.body;
      throw Exception('Error al obtener teléfonos: $msg');
    } catch (e) {
      logger.e('Exception fetching phones: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  /// @deprecated Use [fetchMyPhones] or [fetchPhonesByUserId].
  Future<List<Phone>> fetchPhones(int id) async {
    return fetchPhonesByUserId(id);
  }

  /// Crear teléfono (perfil del usuario autenticado; no se envía profile_id).
  /// Incluye context; si context=commerce/delivery_company, commerce_id/delivery_company_id deben ir en [phone].
  Future<Phone> createPhone(Phone phone, int userId) async {
    try {
      logger.i('Creating phone: ${phone.toString()}');
      final digitsOnly = phone.number.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length != 7) {
        throw Exception('El número debe tener exactamente 7 dígitos');
      }

      final headers = await AuthHelper.getAuthHeaders();
      final payload = phone.toJson();

      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/api/phones'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      logger.i('Create phone response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final createdPhone = Phone.fromJson(Map<String, dynamic>.from(body['data'] as Map));
          logger.i('Phone created successfully: ${createdPhone.id}');
          return createdPhone;
        }
      }
      if (response.statusCode == 422) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = body?['message']?.toString() ?? '';
        final errors = body?['errors'];
        if (message.contains('máximo') || message.contains('registrado') ||
            (errors != null && errors.toString().contains('número'))) {
          throw Exception(message.isNotEmpty ? message : 'Este número ya está registrado o has alcanzado el límite de teléfonos.');
        }
      }
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map ? (decoded['message'] ?? response.body).toString() : response.body;
      throw Exception('Error al crear teléfono: $msg');
    } catch (e) {
      logger.e('Exception creating phone: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  /// Actualizar teléfono.
  Future<Phone> updatePhone(int id, Map<String, dynamic> updates) async {
    try {
      logger.i('Updating phone $id with: $updates');
      final headers = await AuthHelper.getAuthHeaders();

      final response = await http
          .put(
            Uri.parse('${AppConfig.apiUrl}/api/phones/$id'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 10));

      logger.i('Update phone response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return Phone.fromJson(Map<String, dynamic>.from(body['data'] as Map));
        }
      }
      if (response.statusCode == 422) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(body?['message']?.toString() ?? 'Error de validación');
      }
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map ? (decoded['message'] ?? response.body).toString() : response.body;
      throw Exception('Error al actualizar teléfono: $msg');
    } catch (e) {
      logger.e('Exception updating phone: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  Future<void> updatePrimaryStatus(int id, bool isPrimary, int userId) async {
    if (isPrimary) {
      try {
        final phones = await fetchPhonesByUserId(userId);
        for (final phone in phones) {
          if (phone.id != id && phone.isPrimary) {
            await updatePhone(phone.id, {
              'is_primary': false,
              'status': phone.status,
            });
          }
        }
      } catch (_) {}
    }
    try {
      final phones = await fetchPhonesByUserId(userId);
      final currentPhone = phones.firstWhere((phone) => phone.id == id);
      await updatePhone(id, {
        'is_primary': isPrimary,
        'status': currentPhone.status,
      });
    } catch (_) {
      await updatePhone(id, {'is_primary': isPrimary, 'status': true});
    }
  }

  Future<void> updateActiveStatus(int id, bool status, int userId) async {
    try {
      final phones = await fetchPhonesByUserId(userId);
      final currentPhone = phones.firstWhere((phone) => phone.id == id);
      await updatePhone(id, {
        'status': status,
        'is_primary': currentPhone.isPrimary,
      });
    } catch (_) {
      await updatePhone(id, {'status': status, 'is_primary': false});
    }
  }

  Future<void> deletePhone(int id) async {
    try {
      logger.i('Deleting phone: $id');
      final headers = await AuthHelper.getAuthHeaders();

      final response = await http
          .delete(
            Uri.parse('${AppConfig.apiUrl}/api/phones/$id'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      logger.i('Delete phone response: ${response.statusCode}');

      if (response.statusCode == 200) return;
      if (response.statusCode == 404) throw Exception('Teléfono no encontrado');
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map ? (decoded['message'] ?? response.body).toString() : response.body;
      throw Exception('Error al eliminar teléfono: $msg');
    } catch (e) {
      logger.e('Exception deleting phone: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  /// Parsea la respuesta JSON de códigos de operador (compartido por ruta con y sin auth).
  static List<Map<String, dynamic>> _parseOperatorCodesResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (decoded['success'] == true && decoded['data'] != null) {
      final list = decoded['data'] as List;
      return list
          .map<Map<String, dynamic>>((e) => {
                'id': (e as Map)['id'] ?? 0,
                'name': (e)['name'] ?? (e['name']?.toString() ?? ''),
                'code': (e)['code'] ?? (e['code']?.toString() ?? ''),
              })
          .toList();
    }
    return [];
  }

  /// Códigos de operador para dropdown. Prueba con auth; si falla (401/error), usa ruta pública (onboarding).
  Future<List<Map<String, dynamic>>> fetchOperatorCodes() async {
    try {
      logger.i('Fetching operator codes');
      final headers = await AuthHelper.getAuthHeaders();

      final response = await http
          .get(
            Uri.parse('${AppConfig.apiUrl}/api/phones/operator-codes'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      logger.i('Operator codes response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final list = _parseOperatorCodesResponse(response.body);
        if (list.isNotEmpty) return list;
      }
      // Sin auth (401) o respuesta vacía: intentar endpoint público para onboarding
      if (response.statusCode == 401 || response.statusCode == 403) {
        logger.i('Operator codes: trying public endpoint');
        final publicResponse = await http
            .get(
              Uri.parse('${AppConfig.apiUrl}/api/operator-codes'),
              headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));
        if (publicResponse.statusCode == 200) {
          final list = _parseOperatorCodesResponse(publicResponse.body);
          if (list.isNotEmpty) return list;
        }
      }
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map ? (decoded['message'] ?? response.body).toString() : response.body;
      throw Exception('Error al obtener códigos de operador: $msg');
    } catch (e) {
      logger.e('Exception fetching operator codes: $e');
      try {
        final publicResponse = await http
            .get(
              Uri.parse('${AppConfig.apiUrl}/api/operator-codes'),
              headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));
        if (publicResponse.statusCode == 200) {
          final list = _parseOperatorCodesResponse(publicResponse.body);
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  Future<void> updateStatusCheckScanner(int userId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/api/data-verification/$userId/update-status-check-scanner/phones'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(body?['message']?.toString() ?? 'Error al actualizar estado');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      rethrow;
    }
  }

  bool validatePhoneNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length == 7 && int.tryParse(digits) != null;
  }

  /// Formato legible: 0412 123 4567
  String formatPhoneDisplay(String code, String number) {
    final d = number.replaceAll(RegExp(r'\D'), '');
    if (d.length == 7) return '$code ${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5)}';
    return code + number;
  }
}
