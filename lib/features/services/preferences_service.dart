import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class PreferencesService {
  static String get baseUrl => AppConfig.baseUrl;
  static int get requestTimeout => AppConfig.requestTimeout;

  /// Obtener preferencias del usuario
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener preferencias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar preferencias del usuario
  static Future<Map<String, dynamic>> updatePreferences({
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    List<String>? cuisinePreferences,
    String? spiceLevel,
    String? portionSize,
    List<String>? cookingPreferences,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      final Map<String, dynamic> updateData = {};
      
      if (dietaryRestrictions != null) updateData['dietary_restrictions'] = dietaryRestrictions;
      if (allergies != null) updateData['allergies'] = allergies;
      if (cuisinePreferences != null) updateData['cuisine_preferences'] = cuisinePreferences;
      if (spiceLevel != null) updateData['spice_level'] = spiceLevel;
      if (portionSize != null) updateData['portion_size'] = portionSize;
      if (cookingPreferences != null) updateData['cooking_preferences'] = cookingPreferences;

      final response = await http.put(
        Uri.parse('$baseUrl/api/buyer/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar preferencias');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener productos filtrados por preferencias
  static Future<Map<String, dynamic>> getFilteredProducts({
    required int commerceId,
    bool applyFilters = true,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/preferences/filtered-products?commerce_id=$commerceId&apply_filters=$applyFilters'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener productos filtrados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener historial de pedidos con análisis
  static Future<Map<String, dynamic>> getOrderHistory() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/preferences/order-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener historial de pedidos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener recomendaciones personalizadas
  static Future<Map<String, dynamic>> getPersonalizedRecommendations() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/preferences/recommendations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener recomendaciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener menú personalizado para un restaurante
  static Future<Map<String, dynamic>> getPersonalizedMenu({
    required int commerceId,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/preferences/personalized-menu?commerce_id=$commerceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener menú personalizado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener estadísticas de preferencias
  static Future<Map<String, dynamic>> getPreferencesStats() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/preferences/stats'),
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

  /// Obtener opciones de restricciones dietéticas
  static List<Map<String, String>> getDietaryRestrictionsOptions() {
    return [
      {'value': 'vegetarian', 'label': 'Vegetariano', 'icon': '🥬'},
      {'value': 'vegan', 'label': 'Vegano', 'icon': '🌱'},
      {'value': 'gluten_free', 'label': 'Sin Gluten', 'icon': '🌾'},
      {'value': 'dairy_free', 'label': 'Sin Lácteos', 'icon': '🥛'},
      {'value': 'keto', 'label': 'Keto', 'icon': '🥑'},
      {'value': 'paleo', 'label': 'Paleo', 'icon': '🥩'},
      {'value': 'low_carb', 'label': 'Bajo en Carbohidratos', 'icon': '🍞'},
    ];
  }

  /// Obtener opciones de alergias
  static List<Map<String, String>> getAllergiesOptions() {
    return [
      {'value': 'peanuts', 'label': 'Maní', 'icon': '🥜'},
      {'value': 'tree_nuts', 'label': 'Frutos Secos', 'icon': '🌰'},
      {'value': 'milk', 'label': 'Leche', 'icon': '🥛'},
      {'value': 'eggs', 'label': 'Huevos', 'icon': '🥚'},
      {'value': 'soy', 'label': 'Soya', 'icon': '🫘'},
      {'value': 'fish', 'label': 'Pescado', 'icon': '🐟'},
      {'value': 'shellfish', 'label': 'Mariscos', 'icon': '🦐'},
      {'value': 'wheat', 'label': 'Trigo', 'icon': '🌾'},
    ];
  }

  /// Obtener opciones de preferencias de cocina
  static List<Map<String, String>> getCuisinePreferencesOptions() {
    return [
      {'value': 'italian', 'label': 'Italiana', 'icon': '🍝'},
      {'value': 'mexican', 'label': 'Mexicana', 'icon': '🌮'},
      {'value': 'chinese', 'label': 'China', 'icon': '🥢'},
      {'value': 'japanese', 'label': 'Japonesa', 'icon': '🍱'},
      {'value': 'indian', 'label': 'India', 'icon': '🍛'},
      {'value': 'american', 'label': 'Americana', 'icon': '🍔'},
      {'value': 'mediterranean', 'label': 'Mediterránea', 'icon': '🥙'},
    ];
  }

  /// Obtener opciones de nivel de picante
  static List<Map<String, String>> getSpiceLevelOptions() {
    return [
      {'value': 'mild', 'label': 'Suave', 'icon': '🌶️'},
      {'value': 'medium', 'label': 'Medio', 'icon': '🌶️🌶️'},
      {'value': 'hot', 'label': 'Picante', 'icon': '🌶️🌶️🌶️'},
      {'value': 'extra_hot', 'label': 'Muy Picante', 'icon': '🌶️🌶️🌶️🌶️'},
    ];
  }

  /// Obtener opciones de tamaño de porción
  static List<Map<String, String>> getPortionSizeOptions() {
    return [
      {'value': 'small', 'label': 'Pequeña', 'icon': '🍽️'},
      {'value': 'regular', 'label': 'Regular', 'icon': '🍽️🍽️'},
      {'value': 'large', 'label': 'Grande', 'icon': '🍽️🍽️🍽️'},
    ];
  }

  /// Obtener opciones de métodos de cocción
  static List<Map<String, String>> getCookingPreferencesOptions() {
    return [
      {'value': 'grilled', 'label': 'A la Parrilla', 'icon': '🔥'},
      {'value': 'baked', 'label': 'Horneado', 'icon': '🥖'},
      {'value': 'fried', 'label': 'Frito', 'icon': '🍳'},
      {'value': 'steamed', 'label': 'Al Vapor', 'icon': '💨'},
      {'value': 'raw', 'label': 'Crudo', 'icon': '🥗'},
    ];
  }

  /// Calcular puntuación de coincidencia
  static double calculateMatchScore(Map<String, dynamic> product, Map<String, dynamic> preferences) {
    double score = 0.0;
    
    // Puntuación por restricciones dietéticas
    final dietaryRestrictions = preferences['dietary_restrictions'] ?? [];
    for (String restriction in dietaryRestrictions) {
      switch (restriction) {
        case 'vegetarian':
          if (product['is_vegetarian'] == true) score += 20;
          break;
        case 'vegan':
          if (product['is_vegan'] == true) score += 25;
          break;
        case 'gluten_free':
          if (product['is_gluten_free'] == true) score += 20;
          break;
      }
    }
    
    // Puntuación por alergias
    final allergies = preferences['allergies'] ?? [];
    for (String allergy in allergies) {
      final allergens = product['allergens'] ?? '';
      if (!allergens.toLowerCase().contains(allergy.toLowerCase())) {
        score += 15;
      } else {
        score -= 50; // Penalización fuerte por alergias
      }
    }
    
    // Puntuación por popularidad
    final salesCount = product['sales_count'] ?? 0;
    score += (salesCount / 10).clamp(0, 100);
    
    return score;
  }

  /// Obtener banderas dietéticas del producto
  static List<String> getDietaryFlags(Map<String, dynamic> product) {
    final flags = <String>[];
    
    if (product['is_vegetarian'] == true) flags.add('vegetarian');
    if (product['is_vegan'] == true) flags.add('vegan');
    if (product['is_gluten_free'] == true) flags.add('gluten_free');
    if (product['is_dairy_free'] == true) flags.add('dairy_free');
    
    return flags;
  }

  /// Obtener advertencias de alergias
  static List<String> getAllergyWarnings(Map<String, dynamic> product, Map<String, dynamic> preferences) {
    final warnings = <String>[];
    final allergies = preferences['allergies'] ?? [];
    final allergens = product['allergens'] ?? '';
    
    for (String allergy in allergies) {
      if (allergens.toLowerCase().contains(allergy.toLowerCase())) {
        warnings.add('Contiene $allergy');
      }
    }
    
    return warnings;
  }

  /// Verificar si un producto es compatible con las preferencias
  static bool isProductCompatible(Map<String, dynamic> product, Map<String, dynamic> preferences) {
    final score = calculateMatchScore(product, preferences);
    return score > 50;
  }
} 