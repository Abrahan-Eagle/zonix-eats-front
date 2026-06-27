import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:zonix_glasses/config/app_config.dart';
import '../models/adresse.dart';
import '../models/models.dart';

final logger = Logger();

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class AddressService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    // No registrar el token completo (riesgo de seguridad en logs del dispositivo).
    if (token != null && token.isNotEmpty) {
      logger.d('Token de sesión presente (longitud: ${token.length})');
    }
    return token;
  }

  Future<List<Country>> fetchCountries() async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/addresses/getCountries'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] != null)
                ? decoded['data'] as List<dynamic>
                : [];
        return data
            .map((json) => Country.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al cargar los países');
      }
    } catch (e) {
      logger.e('Error en la solicitud de países: $e');
      throw ApiException('Error en la solicitud de países: ${e.toString()}');
    }
  }

  Future<List<StateModel>> fetchStates(int countryId) async {
    final token = await _getToken();
    try {
      final response = await http
          .post(
            Uri.parse(
                '${AppConfig.apiUrl}/api/addresses/get-states-by-country'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'countries_id': countryId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] != null)
                ? decoded['data'] as List<dynamic>
                : [];
        return data
            .map((json) => StateModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al cargar los estados');
      }
    } catch (e) {
      logger.e('Error en la solicitud de estados: $e');
      throw ApiException('Error en la solicitud de estados: ${e.toString()}');
    }
  }

  Future<List<City>> fetchCitiesByState(int stateId) async {
    final token = await _getToken();
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/api/addresses/get-cities-by-state'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'state_id': stateId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] != null)
                ? decoded['data'] as List<dynamic>
                : [];
        return data
            .map((json) => City.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al cargar los ciudades');
      }
    } catch (e) {
      logger.e('Error en la solicitud de ciudades: $e');
      throw ApiException('Error en la solicitud de ciudades: ${e.toString()}');
    }
  }

  /// Crea una dirección.
  /// [profileId] debe ser el id real de profiles.id (canónico).
  /// Por compatibilidad legacy, el backend también puede resolver por user_id.
  /// [role] opcional: 'user', 'admin', etc.
  String _extractApiErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          final errors = decoded['errors'];
          if (errors is Map<String, dynamic>) {
            final firstEntry = errors.entries.firstWhere(
              (entry) => entry.value is List && (entry.value as List).isNotEmpty,
              orElse: () => const MapEntry<String, dynamic>('', null),
            );
            if (firstEntry.key.isNotEmpty && firstEntry.value is List) {
              final firstError = (firstEntry.value as List).first;
              if (firstError is String && firstError.trim().isNotEmpty) {
                return '$message ($firstError)';
              }
            }
          }
          return message;
        }
      }
    } catch (_) {
      // Si el body no es JSON, se usa fallback.
    }

    return responseBody;
  }

  Future<void> createAddress(Address address, int profileId, {String? role}) async {
    final token = await _getToken();
    try {
      final body = <String, dynamic>{
        'profile_id': profileId,
        'street': address.street,
        'house_number': address.houseNumber,
        'city_id': address.cityId,
        'postal_code': address.postalCode,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'status': address.status,
      };
      final effectiveRole = role ?? 'user';
      if (effectiveRole.isNotEmpty) body['role'] = effectiveRole;

      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/api/addresses'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return;
      }
      final errorMessage = _extractApiErrorMessage(response.body);
      logger.e(
          'Error al crear la dirección: ${response.statusCode} $errorMessage');
      throw ApiException('al crear la dirección: $errorMessage');
    } catch (e) {
      if (e is ApiException) rethrow;
      logger.e('Error en la solicitud de creación de dirección: $e');
      throw ApiException(
          'Error en la solicitud de creación de dirección: ${e.toString()}');
    }
  }

  Future<void> updateAddress(Address address, int userId) async {
    logger.w('Actualizando dirección - ID: ${address.id}, UserID: $userId');
    final token = await _getToken();

    logger.d(
        'PUT dirección id=${address.id} → ${AppConfig.apiUrl}/api/addresses/${address.id}');

    try {
      final requestBody = {
        'profile_id': userId,
        'street': address.street,
        'house_number': address.houseNumber,
        'city_id': address.cityId,
        'postal_code': address.postalCode,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'status': address.status,
      };

      logger.i('Actualizando dirección id=${address.id}');

      final response = await http
          .put(
            Uri.parse('${AppConfig.apiUrl}/api/addresses/${address.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('Dirección actualizada exitosamente');
      } else {
        logger.e(
            'Error al actualizar la dirección: ${response.statusCode} ${response.body}');
        throw ApiException(
            'Error al actualizar la dirección: ${response.body}');
      }
    } catch (e) {
      logger.e('Error en la solicitud de actualización de dirección: $e');
      throw ApiException(
          'Error en la solicitud de actualización de dirección: ${e.toString()}');
    }
  }

  Future<Address?> getAddressById(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${AppConfig.apiUrl}/api/addresses/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return Address.fromJson(data.first);
      } else if (data is Map<String, dynamic>) {
        return Address.fromJson(data);
      } else {
        logger.e('Formato de datos inesperado: $data');
        throw ApiException('Error al obtener la dirección: formato inesperado');
      }
    } else {
      logger.e(
          'Error al obtener la dirección: ${response.statusCode} ${response.body}');
      throw ApiException('Error al obtener la dirección: ${response.body}');
    }
  }

  // Obtener una sola ciudad por su ID
  Future<String?> fetchCityById(int cityId) async {
    try {
      final token =
          await _getToken(); // Changed from _storage.read for consistency
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiUrl}/api/cities/$cityId'), // Added /api/ for consistency with other endpoints
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming the endpoint returns the city object or { "city": { "name": "..."} }
        // Given 'get-cities-by-state' returned List of cities with 'name'. Let's assume city has 'name' key.
        return data['name'];
      }
      return null;
    } catch (e) {
      logger.e('Error fetchCityById: $e');
      return null;
    }
  }

  // Actualizar el estado de la dirección (sólo escáneres o admin);
  Future<void> updateStatusCheckScanner(int userId) async {
    String? token = await _getToken();
    if (token == null) {
      logger.e('Token no encontrado');
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.apiUrl}/api/data-verification/$userId/update-status-check-scanner/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        // Si necesitas enviar un cuerpo, puedes descomentar lo siguiente:
        // body: json.encode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ApiException('Error al actualizar el estado: ${response.body}');
      }
    } catch (e) {
      logger.e('Error al actualizar el estado: $e');
      throw ApiException('Error al actualizar el estado: ${e.toString()}');
    }
  }
}
