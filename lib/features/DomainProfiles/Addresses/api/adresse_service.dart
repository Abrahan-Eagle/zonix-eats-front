import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/adresse.dart';
import '../models/models.dart';

final logger = Logger();
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

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
  logger.e('0000000000000000000000000000000000000000000000000000000000000000000000000');
  final token = await _getToken();
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/addresses/getCountries'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    logger.i('00000000000000 Response status: ${response.statusCode}');
    logger.i('00000000000000 Response body: ${response.body}');

  if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los países');
    }
  } catch (e) {
    logger.e('Error en la solicitud de países: $e');
    throw ApiException('Error en la solicitud de países: ${e.toString()}');
  }
}

Future<List<StateModel>> fetchStates(int countryId) async {
  logger.e('1111111111111111111111111111111111111111111111111111111111111111111111111: $countryId');
  final token = await _getToken();
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/addresses/get-states-by-country'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'countries_id': countryId}),
    ).timeout(const Duration(seconds: 10));

    logger.i('11111111111111111 Response status: ${response.statusCode}');
    logger.i('11111111111111111 Response body: ${response.body}');

  if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StateModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los estados');
    }
  } catch (e) {
    logger.e('Error en la solicitud de estados: $e');
    throw ApiException('Error en la solicitud de estados: ${e.toString()}');
  }
}
    
 Future<List<City>> fetchCitiesByState(int stateId) async {
  logger.e('2222222222222222222222222222222222222222222222222222222222222222222222222: $stateId');
  final token = await _getToken();
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/addresses/get-cities-by-state'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'state_id': stateId}),
    ).timeout(const Duration(seconds: 10));

    logger.i('222222222222222 Response status: ${response.statusCode}');
    logger.i('222222222222222 Response body: ${response.body}');

  if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => City.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los ciudades');
    }
  } catch (e) {
    logger.e('Error en la solicitud de ciudades: $e');
    throw ApiException('Error en la solicitud de ciudades: ${e.toString()}');
  }
}



  Future<void> createAddress(Address address, int userId) async {

    logger.w('addressUSERID: ${address.id}  userIduserIduserIdUSERID: $userId  createAddress: ${address.latitude} ${address.longitude}');
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'profile_id': userId,
          'street': address.street,
          'house_number': address.houseNumber,
          'city_id': address.cityId,
          'postal_code': address.postalCode,
          'latitude': address.latitude,
          'longitude': address.longitude,
          'status': address.status,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        logger.e('Error al crear la dirección: ${response.statusCode} ${response.body}');
        throw ApiException('al crear la dirección: ${response.body}');
      }
    } catch (e) {
      logger.e('Error en la solicitud de creación de dirección: $e');
      throw ApiException('Error en la solicitud de creación de dirección: ${e.toString()}');
    }
  }

  Future<Address?> getAddressById(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/addresses/$id'),
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

  // Método auxiliar para manejar la respuesta de la API
  _handleResponse<T>(http.Response response, T Function(dynamic) fromJson) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return fromJson(data);
    } else {
      logger.e('Error en la solicitud: ${response.statusCode} ${response.body}');
      throw ApiException('Error en la solicitud: ${response.statusCode} ${response.body}');
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
      Uri.parse('$baseUrl/api/data-verification/$userId/update-status-check-scanner/addresses'),
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
