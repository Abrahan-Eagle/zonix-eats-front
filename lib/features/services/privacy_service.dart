import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';

class PrivacyService {
  static const String baseUrl = 'http://localhost:8000/api';

  // Obtener configuración actual de privacidad
  static Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/privacy-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener configuración: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar configuración de privacidad
  static Future<Map<String, dynamic>> updatePrivacySettings({
    bool? profileVisibility,
    bool? orderHistoryVisibility,
    bool? activityVisibility,
    bool? marketingEmails,
    bool? pushNotifications,
    bool? locationSharing,
    bool? dataAnalytics,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final settings = <String, dynamic>{};
      if (profileVisibility != null) settings['profile_visibility'] = profileVisibility;
      if (orderHistoryVisibility != null) settings['order_history_visibility'] = orderHistoryVisibility;
      if (activityVisibility != null) settings['activity_visibility'] = activityVisibility;
      if (marketingEmails != null) settings['marketing_emails'] = marketingEmails;
      if (pushNotifications != null) settings['push_notifications'] = pushNotifications;
      if (locationSharing != null) settings['location_sharing'] = locationSharing;
      if (dataAnalytics != null) settings['data_analytics'] = dataAnalytics;

      final response = await http.put(
        Uri.parse('$baseUrl/user/privacy-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al actualizar configuración: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener política de privacidad
  static Future<Map<String, dynamic>> getPrivacyPolicy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/privacy-policy'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener política: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener términos de servicio
  static Future<Map<String, dynamic>> getTermsOfService() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/terms-of-service'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener términos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 