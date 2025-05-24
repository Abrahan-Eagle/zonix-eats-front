import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix_eats/features/DomainProfiles/Addresses/api/adresse_service.dart';
import '../models/phone.dart';

final logger = Logger();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class PhoneService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<List<Phone>> fetchPhones(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.get(
      Uri.parse('$baseUrl/api/phones/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Phone.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener teléfonos');
    }
  }

  Future<void> createPhone(Phone phone, int userId) async {
     logger.i('Phone phonePhone phonePhone phonePhone phone: $phone');
    final token = await _getToken();
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.post(
      Uri.parse('$baseUrl/api/phones'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(phone.toJson()),
    );

    if (response.statusCode != 201) {
      logger.e('Error al crear teléfono: ${response.body}');
      throw Exception('Error al crear teléfono');
    }
  }

  Future<void> updatePhone(int id, bool isPrimary) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.put(
      Uri.parse('$baseUrl/api/phones/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_primary': isPrimary}),
    );

    if (response.statusCode != 200) {
      logger.e('Error al actualizar teléfono: ${response.body}');
      throw Exception('Error al actualizar teléfono');
    }
  }

  Future<void> deletePhone(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/phones/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      logger.e('Error al eliminar teléfono: ${response.body}');
      throw Exception('Error al eliminar teléfono');
    }
  }

  // Método para obtener los códigos de operador
  Future<List<Map<String, dynamic>>> fetchOperatorCodes() async {
    final token = await _getToken();
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.get(
      Uri.parse('$baseUrl/api/phones'), // Asegúrate de que esta sea la URL correcta
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Mapeamos los datos a una lista de Map
      return data.map<Map<String, dynamic>>((e) {
        return {
          'id': e['id'], // Ajusta según el formato de tu API
          'name': e['name'], // Ajusta según el formato de tu API
        };
      }).toList();
    } else {
      logger.e('Error al obtener códigos de operador: ${response.body}');
      throw Exception('Error al obtener códigos de operador');
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
      Uri.parse('$baseUrl/api/data-verification/$userId/update-status-check-scanner/phones'),
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
