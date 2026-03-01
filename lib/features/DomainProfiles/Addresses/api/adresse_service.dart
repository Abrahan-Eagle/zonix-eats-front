import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:zonix/config/app_config.dart';
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
    logger.i('Token recuperado: $token');
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
      return data.map((json) => Country.fromJson(json as Map<String, dynamic>)).toList();
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
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/addresses/get-states-by-country'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'countries_id': countryId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> data = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] != null)
              ? decoded['data'] as List<dynamic>
              : [];
      return data.map((json) => StateModel.fromJson(json as Map<String, dynamic>)).toList();
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
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/addresses/get-cities-by-state'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'state_id': stateId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> data = decoded is List
          ? decoded
          : (decoded is Map && decoded['data'] != null)
              ? decoded['data'] as List<dynamic>
              : [];
      return data.map((json) => City.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error al cargar los ciudades');
    }
  } catch (e) {
    logger.e('Error en la solicitud de ciudades: $e');
    throw ApiException('Error en la solicitud de ciudades: ${e.toString()}');
  }
}



  /// Crea una dirección. [userId] es el user_id del usuario (el backend lo espera en profile_id).
  /// [role] opcional: 'users', 'commerce', 'delivery', 'admin'.
  /// [commerceId] opcional: cuando la dirección es del establecimiento (role commerce), vincula a este comercio.
  Future<void> createAddress(Address address, int userId, {String? role, int? commerceId}) async {
    final token = await _getToken();
    try {
      // Opción A: dirección del establecimiento → solo commerce_id (no enviar profile_id).
      final isCommerceAddress = commerceId != null && commerceId > 0;
      final body = <String, dynamic>{
        'street': address.street,
        'house_number': address.houseNumber,
        'city_id': address.cityId,
        'postal_code': address.postalCode,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'status': address.status,
      };
      if (isCommerceAddress) {
        body['commerce_id'] = commerceId;
        body['role'] = role ?? 'commerce';
      } else {
        body['profile_id'] = userId;
        if (role != null && role.isNotEmpty) body['role'] = role;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return;
      }
      if (response.statusCode == 409) {
        final resBody = response.body;
        if (resBody.contains('Ya tiene un registro guardado') ||
            (resBody.isNotEmpty && resBody.contains('registro guardado'))) {
          return;
        }
      }
      logger.e('Error al crear la dirección: ${response.statusCode} ${response.body}');
      throw ApiException('al crear la dirección: ${response.body}');
    } catch (e) {
      if (e is ApiException) rethrow;
      logger.e('Error en la solicitud de creación de dirección: $e');
      throw ApiException('Error en la solicitud de creación de dirección: ${e.toString()}');
    }
  }

  Future<void> updateAddress(Address address, int userId) async {
    logger.w('Actualizando dirección - ID: ${address.id}, UserID: $userId');
    final token = await _getToken();
    
    logger.i('Token obtenido: $token');
    logger.i('URL de actualización: ${AppConfig.apiUrl}/api/addresses/${address.id}');
    
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
      
      logger.i('Datos a enviar: ${json.encode(requestBody)}');
      
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/api/addresses/${address.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));

      logger.i('Response status: ${response.statusCode}');
      logger.i('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('Dirección actualizada exitosamente');
      } else {
        logger.e('Error al actualizar la dirección: ${response.statusCode} ${response.body}');
        throw ApiException('Error al actualizar la dirección: ${response.body}');
      }
    } catch (e) {
      logger.e('Error en la solicitud de actualización de dirección: $e');
      throw ApiException('Error en la solicitud de actualización de dirección: ${e.toString()}');
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
      logger.e('Error al obtener la dirección: ${response.statusCode} ${response.body}');
      throw ApiException('Error al obtener la dirección: ${response.body}');
    }
  }

  Future<void> updateStatusCheckScanner(int userId) async {
  String? token = await _getToken();
    if (token == null) {
      logger.e('Token no encontrado');
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

  try {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/data-verification/$userId/update-status-check-scanner/addresses'),
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
  }catch (e) {
    logger.e('Error al actualizar el estado: $e');
    throw ApiException('Error al actualizar el estado: ${e.toString()}');
  }
}
}
