import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/features/DomainProfiles/GasCylinder/models/gas_cylinder.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final logger = Logger();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class GasCylinderService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<List<GasCylinder>> fetchGasCylinders(int id) async {
    logger.i('Fetching cylinders for user ID: $id');
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final response = await http.get(
        Uri.parse('$baseUrl/api/cylinders/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => GasCylinder.fromJson(e)).toList();
      } else {
        logger.e('Error al obtener las bombonas: ${response.body}');
        throw Exception('Error al obtener las bombonas.');
      }
    } catch (e) {
      logger.e('fetchGasCylinders error: $e');
      rethrow;
    }
  }

Future<List<Map<String, dynamic>>> getGasSuppliers() async {
  String? token = await _getToken();

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cylinders/getGasSuppliers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    logger.i('Response: ${response.body}'); // Verificar la respuesta

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al cargar proveedores: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de red: $e');
  }
}

  // Método para crear una nueva bombona
  Future<void> createGasCylinder(GasCylinder cylinder, int userId, {File? imageFile}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/cylinders'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['gas_cylinder_code'] = cylinder.gasCylinderCode;
      request.fields['user_id'] = userId.toString();
      request.fields['company_supplier_id'] = cylinder.companySupplierId.toString();
      
      // Campos adicionales según el modelo
      if (cylinder.cylinderType != null) {
        request.fields['cylinder_type'] = cylinder.cylinderType!;
      }
      if (cylinder.cylinderWeight != null) {
        request.fields['cylinder_weight'] = cylinder.cylinderWeight!;
      }
      if (cylinder.manufacturingDate != null) {
        request.fields['manufacturing_date'] = cylinder.manufacturingDate!.toIso8601String();
      }

      // Manejo de la imagen
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo_gas_cylinder', // Cambia esto si tu API espera un nombre diferente
          imageFile.path,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        logger.i('Bombona creada exitosamente.');
      } else {
        final responseBody = await response.stream.bytesToString();
        logger.e('Error al crear la bombona: $responseBody');
        throw Exception('Error al crear la bombona: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      logger.e('createGasCylinder error: $e');
      rethrow;
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
      Uri.parse('$baseUrl/api/data-verification/$userId/update-status-check-scanner/gas-cylinders'),
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
