import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class ExportService {
  static String get baseUrl => AppConfig.baseUrl;

  // Solicitar exportación de datos personales
  static Future<Map<String, dynamic>> requestDataExport({
    List<String>? dataTypes,
    String? format = 'json',
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/export-data'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/export-status/$exportId'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/download-export/$exportId'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/export-history'),
        headers: headers,
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