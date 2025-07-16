import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class LoyaltyService {
  static String get baseUrl => AppConfig.baseUrl;
  static int get requestTimeout => AppConfig.requestTimeout;

  /// Obtener información del programa de lealtad
  static Future<Map<String, dynamic>> getLoyaltyInfo() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/loyalty/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener información de lealtad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener descuentos por volumen
  static Future<Map<String, dynamic>> getVolumeDiscounts() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/loyalty/volume-discounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener descuentos por volumen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Generar código de referido
  static Future<Map<String, dynamic>> generateReferralCode() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/loyalty/referral-code'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al generar código de referido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Aplicar código de referido
  static Future<Map<String, dynamic>> applyReferralCode(String referralCode) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/loyalty/apply-referral'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'referral_code': referralCode}),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al aplicar código de referido');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener historial de beneficios
  static Future<Map<String, dynamic>> getBenefitsHistory() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/loyalty/benefits-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener historial de beneficios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener estadísticas de fidelización
  static Future<Map<String, dynamic>> getLoyaltyStats() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/loyalty/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas de lealtad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener próximos beneficios disponibles
  static Future<Map<String, dynamic>> getUpcomingBenefits() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/loyalty/upcoming-benefits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener próximos beneficios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Calcular nivel de lealtad basado en gastos
  static Map<String, dynamic> calculateLoyaltyLevel(double totalSpent) {
    if (totalSpent >= 1000) {
      return {
        'level': 4,
        'name': 'Diamante',
        'color': '#B9F2FF',
        'benefits': [
          'Descuento 15% en todos los pedidos',
          'Envío gratis siempre',
          'Acceso prioritario a promociones',
          'Soporte VIP'
        ]
      };
    } else if (totalSpent >= 500) {
      return {
        'level': 3,
        'name': 'Oro',
        'color': '#FFD700',
        'benefits': [
          'Descuento 10% en todos los pedidos',
          'Envío gratis en pedidos > \$30',
          'Acceso a promociones exclusivas'
        ]
      };
    } else if (totalSpent >= 200) {
      return {
        'level': 2,
        'name': 'Plata',
        'color': '#C0C0C0',
        'benefits': [
          'Descuento 5% en todos los pedidos',
          'Envío gratis en pedidos > \$50'
        ]
      };
    } else {
      return {
        'level': 1,
        'name': 'Bronce',
        'color': '#CD7F32',
        'benefits': [
          'Descuento 2% en todos los pedidos'
        ]
      };
    }
  }

  /// Calcular descuento actual basado en gasto mensual
  static int getCurrentDiscount(double monthlySpent) {
    if (monthlySpent >= 500) return 15;
    if (monthlySpent >= 300) return 10;
    if (monthlySpent >= 100) return 5;
    return 0;
  }

  /// Verificar si se puede aplicar un descuento por volumen
  static bool canApplyVolumeDiscount(double monthlySpent, double threshold) {
    return monthlySpent >= threshold;
  }

  /// Calcular progreso hacia el siguiente umbral de descuento
  static double calculateVolumeProgress(double monthlySpent, double nextThreshold) {
    if (nextThreshold == 0) return 1.0;
    return (monthlySpent / nextThreshold).clamp(0.0, 1.0);
  }

  /// Obtener icono del nivel de lealtad
  static String getLoyaltyLevelIcon(int level) {
    switch (level) {
      case 4:
        return '💎';
      case 3:
        return '🥇';
      case 2:
        return '🥈';
      case 1:
        return '🥉';
      default:
        return '⭐';
    }
  }

  /// Formatear código de referido para mostrar
  static String formatReferralCode(String code) {
    if (code.length <= 8) return code;
    return '${code.substring(0, 4)}...${code.substring(code.length - 4)}';
  }

  /// Validar formato de código de referido
  static bool isValidReferralCode(String code) {
    return code.length >= 6 && code.startsWith('REF_');
  }
} 