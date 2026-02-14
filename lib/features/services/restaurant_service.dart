

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../models/restaurant.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class RestaurantService {
  final String apiUrl = '${AppConfig.apiUrl}/api/buyer/restaurants';
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // GET /api/buyer/restaurants - Listar restaurantes
  Future<List<Restaurant>> fetchRestaurants() async {
    logger.i('Fetching restaurants list');
    
    try {
      final headers = await AuthHelper.getAuthHeaders();
      logger.d('Making GET request to: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      logger.i('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        logger.d('Processing successful response');
        final data = jsonDecode(response.body);
        
        // Backend Laravel: paginador { data: [...], current_page, ... } o array directo
        List<dynamic> restaurantsData;
        if (data is List) {
          restaurantsData = data;
        } else if (data is Map) {
          if (data['data'] != null && data['data'] is List) {
            restaurantsData = data['data'] as List;
          } else if (data['success'] == true && data['data'] != null && data['data'] is List) {
            restaurantsData = data['data'] as List;
          } else {
            restaurantsData = [];
          }
        } else {
          restaurantsData = [];
        }
        
        if (restaurantsData.isNotEmpty) {
          logger.i('Successfully mapped ${restaurantsData.length} restaurants');
          return restaurantsData.map((json) => Restaurant.fromJson(json)).toList();
        } else {
          logger.w('Empty restaurants list received');
          return [];
        }
      } else {
        logger.e('API Error Response: Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('Exception in fetchRestaurants', error: e, stackTrace: stack);
      throw Exception('Restaurants fetch failed: ${e.toString()}');
    }
  }

  // GET /api/buyer/restaurants/{id} - Obtener detalle de restaurante
  Future<Restaurant> fetchRestaurantDetails(int restaurantId) async {
    logger.i('Fetching details for restaurant ID: $restaurantId');
    
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = '$apiUrl/$restaurantId';
      logger.d('Making GET request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      logger.i('API Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        logger.d('Processing restaurant details');
        final data = jsonDecode(response.body);
        
        // Handle the new API response structure
        Map<String, dynamic> restaurantData;
        if (data is Map && data['success'] == true && data['data'] != null) {
          restaurantData = Map<String, dynamic>.from(data['data']);
        } else {
          // Fallback to direct data if not wrapped
          restaurantData = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        }
        
        return Restaurant.fromJson(restaurantData);
      } else {
        logger.e('API Details Error: Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load restaurant details: ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('Exception in fetchRestaurantDetails', error: e, stackTrace: stack);
      throw Exception('Restaurant details fetch failed: ${e.toString()}');
    }
  }

  // Alias method for backward compatibility
  Future<Restaurant> fetchRestaurantDetails2(int commerceId) async {
    return await fetchRestaurantDetails(commerceId);
  }

  // Alias method for backward compatibility
  Future<List<Restaurant>> getRestaurants() async {
    return await fetchRestaurants();
  }
}


