import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class GamificationService {
  static String get baseUrl => AppConfig.apiUrl;
  static int get requestTimeout => AppConfig.requestTimeout;

  /// Obtener puntos y nivel del usuario
  static Future<Map<String, dynamic>> getUserPoints() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/gamification/points'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener puntos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener recompensas disponibles
  static Future<Map<String, dynamic>> getAvailableRewards() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/gamification/rewards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener recompensas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Canjear recompensa
  static Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/gamification/redeem'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reward_id': rewardId}),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al canjear recompensa');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener badges del usuario
  static Future<Map<String, dynamic>> getUserBadges() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/gamification/badges'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener badges: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener leaderboard
  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/gamification/leaderboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener estadísticas de gamificación
  static Future<Map<String, dynamic>> getGamificationStats() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/gamification/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Calcular nivel basado en puntos
  static int calculateLevel(int points) {
    return (points / 100).floor() + 1;
  }

  /// Calcular progreso hacia el siguiente nivel
  static double calculateLevelProgress(int points) {
    return (points % 100) / 100.0;
  }

  /// Obtener puntos necesarios para el siguiente nivel
  static int getPointsToNextLevel(int points) {
    return 100 - (points % 100);
  }

  /// Verificar si se puede canjear una recompensa
  static bool canRedeemReward(int currentPoints, int requiredPoints) {
    return currentPoints >= requiredPoints;
  }

  /// Obtener color del nivel
  static String getLevelColor(int level) {
    if (level >= 10) return '#FFD700'; // Oro
    if (level >= 5) return '#C0C0C0'; // Plata
    if (level >= 2) return '#CD7F32'; // Bronce
    return '#8B4513'; // Marrón
  }

  /// Obtener nombre del nivel
  static String getLevelName(int level) {
    if (level >= 10) return 'Maestro';
    if (level >= 5) return 'Experto';
    if (level >= 2) return 'Intermedio';
    return 'Principiante';
  }
} 