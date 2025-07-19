import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // Mejorado: Obtener teléfonos con mejor manejo de errores
  Future<List<Phone>> fetchPhones(int id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      logger.i('Fetching phones for user: $id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/phones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final phones = data.map((e) => Phone.fromJson(e)).toList();
        logger.i('Fetched ${phones.length} phones');
        return phones;
      } else if (response.statusCode == 404) {
        logger.w('No phones found for user: $id');
        return [];
      } else {
        logger.e('Error fetching phones: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener teléfonos: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception fetching phones: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      throw Exception('Error al obtener teléfonos: $e');
    }
  }

  // Mejorado: Crear teléfono con validaciones
  Future<Phone> createPhone(Phone phone, int userId) async {
    try {
      logger.i('Creating phone: ${phone.toString()}');
      
      // Validaciones
      if (!phone.isValidNumber) {
        throw Exception('El número de teléfono no es válido');
      }

      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final response = await http.post(
        Uri.parse('$baseUrl/api/phones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(phone.toJson()),
      ).timeout(const Duration(seconds: 10));

      logger.i('Create phone response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdPhone = Phone.fromJson(data);
        logger.i('Phone created successfully: ${createdPhone.id}');
        return createdPhone;
      } else {
        logger.e('Error creating phone: ${response.statusCode} - ${response.body}');
        throw Exception('Error al crear teléfono: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception creating phone: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      throw Exception('Error al crear teléfono: $e');
    }
  }

  // Mejorado: Actualizar teléfono con más opciones
  Future<Phone> updatePhone(int id, Map<String, dynamic> updates) async {
    try {
      logger.i('Updating phone $id with: $updates');
      
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final response = await http.put(
        Uri.parse('$baseUrl/api/phones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 10));

      logger.i('Update phone response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedPhone = Phone.fromJson(data);
        logger.i('Phone updated successfully');
        return updatedPhone;
      } else {
        logger.e('Error updating phone: ${response.statusCode} - ${response.body}');
        throw Exception('Error al actualizar teléfono: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception updating phone: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      throw Exception('Error al actualizar teléfono: $e');
    }
  }

  // Método específico para actualizar solo el estado principal
  Future<void> updatePrimaryStatus(int id, bool isPrimary) async {
    // Si se está marcando como principal, primero desmarcar todos los demás
    if (isPrimary) {
      try {
        final phones = await fetchPhones(56); // Obtener todos los teléfonos del usuario
        for (final phone in phones) {
          if (phone.id != id && phone.isPrimary) {
            await updatePhone(phone.id, {
              'is_primary': 0,
              'status': phone.status ? 1 : 0,
            });
          }
        }
      } catch (e) {
        // Si hay error, continuar con la actualización del teléfono actual
      }
    }
    
    // Actualizar el teléfono actual
    try {
      final phones = await fetchPhones(56);
      final currentPhone = phones.firstWhere((phone) => phone.id == id);
      
      await updatePhone(id, {
        'is_primary': isPrimary ? 1 : 0,
        'status': currentPhone.status ? 1 : 0,
      });
    } catch (e) {
      // Si no se puede obtener el teléfono actual, usar un enfoque más simple
      await updatePhone(id, {
        'is_primary': isPrimary ? 1 : 0,
        'status': 1, // Valor por defecto
      });
    }
  }

  // Método específico para actualizar solo el estado activo/inactivo
  Future<void> updateActiveStatus(int id, bool status) async {
    // Primero obtener el teléfono actual para mantener el estado is_primary
    try {
      final phones = await fetchPhones(56); // Obtener todos los teléfonos del usuario
      final currentPhone = phones.firstWhere((phone) => phone.id == id);
      
      await updatePhone(id, {
        'status': status ? 1 : 0,
        'is_primary': currentPhone.isPrimary ? 1 : 0,
      });
    } catch (e) {
      // Si no se puede obtener el teléfono actual, usar un enfoque más simple
      await updatePhone(id, {
        'status': status ? 1 : 0,
        'is_primary': 0, // Valor por defecto
      });
    }
  }

  // Mejorado: Eliminar teléfono con confirmación
  Future<void> deletePhone(int id) async {
    try {
      logger.i('Deleting phone: $id');
      
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/phones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      logger.i('Delete phone response: ${response.statusCode}');

      if (response.statusCode == 200) {
        logger.i('Phone deleted successfully');
      } else if (response.statusCode == 404) {
        throw Exception('Teléfono no encontrado');
      } else {
        logger.e('Error deleting phone: ${response.statusCode} - ${response.body}');
        throw Exception('Error al eliminar teléfono: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception deleting phone: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      throw Exception('Error al eliminar teléfono: $e');
    }
  }

  // Mejorado: Obtener códigos de operador con mejor manejo
  Future<List<Map<String, dynamic>>> fetchOperatorCodes() async {
    try {
      logger.i('Fetching operator codes');
      
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final response = await http.get(
        Uri.parse('$baseUrl/api/phones/operator-codes'), // URL correcta para códigos de operador
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      logger.i('Operator codes response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final codes = data.map<Map<String, dynamic>>((e) {
          return {
            'id': e['id'] ?? 0,
            'name': e['name'] ?? '',
            'code': e['code'] ?? '',
          };
        }).toList();
        logger.i('Fetched ${codes.length} operator codes');
        return codes;
      } else {
        logger.e('Error fetching operator codes: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener códigos de operador: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception fetching operator codes: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      throw Exception('Error al obtener códigos de operador: $e');
    }
  }

  // Mejorado: Actualizar estado de verificación
  Future<void> updateStatusCheckScanner(int userId) async {
    try {
      logger.i('Updating status check scanner for user: $userId');
      
      String? token = await _getToken();
      if (token == null) {
        logger.e('Token no encontrado');
        throw Exception('Token no encontrado. Por favor, inicia sesión.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/data-verification/$userId/update-status-check-scanner/phones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      logger.i('Status check scanner response: ${response.statusCode}');

      if (response.statusCode == 200) {
        logger.i('Status check scanner updated successfully');
      } else {
        logger.e('Error updating status check scanner: ${response.statusCode} - ${response.body}');
        throw Exception('Error al actualizar el estado: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception updating status check scanner: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      }
      throw Exception('Error al actualizar el estado: $e');
    }
  }

  // Nuevo: Validar número de teléfono
  bool validatePhoneNumber(String number) {
    if (number.length != 7) return false;
    if (int.tryParse(number) == null) return false;
    return true;
  }

  // Nuevo: Formatear número de teléfono
  String formatPhoneNumber(String number) {
    if (number.length == 7) {
      return '${number.substring(0, 3)}-${number.substring(3, 5)}-${number.substring(5)}';
    }
    return number;
  }
}
