import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class SearchService {
  final Logger _logger = Logger();

  // GET /api/buyer/search/restaurants - Buscar restaurantes
  // Lógica de geolocalización:
  // - Rango inicial: 1-1.5 km (1500 metros)
  // - Si no encuentra comercios abiertos, expansión automática a 4-5 km (5000 metros)
  // - Usuario puede ampliar manualmente el rango si desea buscar más lejos
  Future<List<Map<String, dynamic>>> searchRestaurants({
    String? query,
    String? category,
    double? latitude,
    double? longitude,
    double? radius, // Por defecto 1.5 km (1500 metros), expansión automática a 5 km (5000 metros)
    String? sortBy,
    String? order,
    int? page,
    int? limit,
  }) async {
    // Si no se especifica radius, usar 1.5 km por defecto (1500 metros)
    final defaultRadius = radius ?? 1.5;
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (query != null) queryParams['query'] = query;
      if (category != null) queryParams['category'] = category;
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      // Radius en km: por defecto 1.5 km, expansión automática a 5 km si no hay comercios abiertos
      queryParams['radius'] = defaultRadius.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (order != null) queryParams['order'] = order;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/search/restaurants')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al buscar restaurantes: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en searchRestaurants: $e');
      throw Exception('Error al buscar restaurantes: $e');
    }
  }

  // GET /api/buyer/search/products - Buscar productos
  Future<List<Map<String, dynamic>>> searchProducts({
    String? query,
    String? category,
    int? commerceId,
    double? minPrice,
    double? maxPrice,
    List<String>? tags,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    String? sortBy,
    String? order,
    int? page,
    int? limit,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (query != null) queryParams['query'] = query;
      if (category != null) queryParams['category'] = category;
      if (commerceId != null) queryParams['commerce_id'] = commerceId.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (tags != null) queryParams['tags'] = tags.join(',');
      if (isVegetarian != null) queryParams['is_vegetarian'] = isVegetarian.toString();
      if (isVegan != null) queryParams['is_vegan'] = isVegan.toString();
      if (isGlutenFree != null) queryParams['is_gluten_free'] = isGlutenFree.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (order != null) queryParams['order'] = order;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/search/products')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al buscar productos: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en searchProducts: $e');
      throw Exception('Error al buscar productos: $e');
    }
  }

  // GET /api/buyer/search/categories - Obtener categorías
  Future<List<Map<String, dynamic>>> getCategories({
    String? type,
    int? commerceId,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (type != null) queryParams['type'] = type;
      if (commerceId != null) queryParams['commerce_id'] = commerceId.toString();

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/search/categories')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getCategories: $e');
      throw Exception('Error al obtener categorías: $e');
    }
  }

  // GET /api/buyer/search/suggestions - Obtener sugerencias de búsqueda
  Future<List<String>> getSearchSuggestions({
    String? query,
    String? type,
    int? limit,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (query != null) queryParams['query'] = query;
      if (type != null) queryParams['type'] = type;
      if (limit != null) queryParams['limit'] = limit.toString();

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/search/suggestions')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener sugerencias: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getSearchSuggestions: $e');
      throw Exception('Error al obtener sugerencias: $e');
    }
  }
} 