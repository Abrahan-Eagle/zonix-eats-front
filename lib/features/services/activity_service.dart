import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class ActivityService {
  static String get baseUrl => AppConfig.baseUrl;

  // Obtener historial de actividad del usuario
  static Future<List<Map<String, dynamic>>> getUserActivityHistory({
    int? page = 1,
    int? limit = 20,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (activityType != null) queryParams['activity_type'] = activityType;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      final uri = Uri.parse('$baseUrl/user/activity-history').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error al obtener historial de actividad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estadísticas de actividad
  static Future<Map<String, dynamic>> getActivityStats() async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/activity-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 