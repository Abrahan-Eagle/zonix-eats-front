import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';

class ExportService {
  static const String baseUrl = 'http://localhost:8000/api';

  // Solicitar exportación de datos personales
  static Future<Map<String, dynamic>> requestDataExport({
    List<String>? dataTypes,
    String? format = 'json',
  }) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/export-data'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data_types': dataTypes ?? ['profile', 'orders', 'activity'],
          'format': format,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al solicitar exportación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar estado de la exportación
  static Future<Map<String, dynamic>> getExportStatus(String exportId) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/export-status/$exportId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al verificar estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Descargar archivo exportado
  static Future<String> downloadExport(String exportId) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/download-export/$exportId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Error al descargar archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener historial de exportaciones
  static Future<List<Map<String, dynamic>>> getExportHistory() async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/export-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 