

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../models/restaurant.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import '../utils/http_retry.dart';

class RestaurantService {
  final String apiUrl = '${AppConfig.apiUrl}/api/buyer/restaurants';
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static const String _cacheKey = 'restaurants_list';

  /// Stale-while-revalidate: returns cached restaurant list instantly.
  static Future<List<Restaurant>?> getCachedRestaurants() async {
    final cached = await CacheService.getRawJson(_cacheKey);
    if (cached == null) return null;
    final list = jsonDecode(cached) as List;
    return list.map((j) => Restaurant.fromJson(j as Map<String, dynamic>)).toList();
  }

  // GET /api/buyer/restaurants - Listar restaurantes (with cache + retry)
  Future<List<Restaurant>> fetchRestaurants() async {
    logger.i('Fetching restaurants list');

    if (!ConnectivityService.isConnected) {
      final cached = await CacheService.getRawJson(_cacheKey);
      if (cached != null) {
        logger.i('Offline: returning cached restaurants');
        return (jsonDecode(cached) as List).map((j) => Restaurant.fromJson(j)).toList();
      }
    }

    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await withRetry(() => http.get(Uri.parse(apiUrl), headers: headers));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> restaurantsData;
        if (data is List) {
          restaurantsData = data;
        } else if (data is Map) {
          restaurantsData = (data['data'] is List) ? data['data'] as List : [];
        } else {
          restaurantsData = [];
        }

        logger.i('Successfully mapped ${restaurantsData.length} restaurants');
        CacheService.setRawJson(_cacheKey, jsonEncode(restaurantsData), expiration: const Duration(hours: 2));
        return restaurantsData.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('fetchRestaurants network error, trying cache', error: e, stackTrace: stack);
      final cached = await CacheService.getRawJson(_cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return list.map((j) => Restaurant.fromJson(j)).toList();
      }
      rethrow;
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


