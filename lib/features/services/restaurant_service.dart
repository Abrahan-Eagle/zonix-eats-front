

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../models/restaurant.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import '../utils/http_retry.dart';

class RestaurantsPageResult {
  const RestaurantsPageResult({
    required this.restaurants,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Restaurant> restaurants;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

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
  static final Map<int, Restaurant> _detailsCache = {};

  /// Stale-while-revalidate: returns cached restaurant list instantly.
  static Future<List<Restaurant>?> getCachedRestaurants() async {
    final cached = await CacheService.getRawJson(_cacheKey);
    if (cached == null) return null;
    final list = jsonDecode(cached) as List;
    return list.map((j) => Restaurant.fromJson(j as Map<String, dynamic>)).toList();
  }

  RestaurantsPageResult _parseRestaurantsPageResult(
    dynamic data, {
    required int fallbackPage,
  }) {
    List<dynamic> restaurantsData = [];
    int currentPage = fallbackPage;
    int lastPage = fallbackPage;
    int total = 0;

    if (data is List) {
      restaurantsData = data;
      total = restaurantsData.length;
    } else if (data is Map) {
      final payload = data['data'];
      if (payload is List) {
        restaurantsData = payload;
      } else if (payload is Map) {
        if (payload['items'] is List) {
          restaurantsData = payload['items'] as List;
        } else if (payload['data'] is List) {
          restaurantsData = payload['data'] as List;
        } else if (payload['restaurants'] is List) {
          restaurantsData = payload['restaurants'] as List;
        }

        currentPage = (payload['current_page'] as num?)?.toInt() ?? currentPage;
        lastPage = (payload['last_page'] as num?)?.toInt() ?? lastPage;
        total = (payload['total'] as num?)?.toInt() ?? total;

        final pagination = payload['pagination'];
        if (pagination is Map) {
          currentPage = (pagination['current_page'] as num?)?.toInt() ?? currentPage;
          lastPage = (pagination['last_page'] as num?)?.toInt() ?? lastPage;
          total = (pagination['total'] as num?)?.toInt() ?? total;
        }
      }
    }

    final restaurants = restaurantsData
        .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
        .toList();

    if (total == 0) {
      total = restaurants.length;
    }

    return RestaurantsPageResult(
      restaurants: restaurants,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  // GET /api/buyer/restaurants - Listar restaurantes paginados.
  Future<RestaurantsPageResult> fetchRestaurantsPage({
    required int page,
    int perPage = 15,
  }) async {
    logger.i('Fetching restaurants page $page');

    if (!ConnectivityService.isConnected) {
      final cached = await CacheService.getRawJson(_cacheKey);
      if (cached != null && page == 1) {
        logger.i('Offline: returning cached restaurants');
        final list = (jsonDecode(cached) as List).map((j) => Restaurant.fromJson(j)).toList();
        return RestaurantsPageResult(
          restaurants: list,
          currentPage: 1,
          lastPage: 1,
          total: list.length,
        );
      }
    }

    try {
      final headers = await AuthHelper.getAuthHeaders();
      final uri = Uri.parse(apiUrl).replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      });
      final response = await withRetry(() => http.get(uri, headers: headers));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _parseRestaurantsPageResult(data, fallbackPage: page);
        logger.i('Successfully mapped ${result.restaurants.length} restaurants');
        if (page == 1) {
          CacheService.setRawJson(
            _cacheKey,
            jsonEncode(result.restaurants.map((r) => r.toJson()).toList()),
            expiration: const Duration(hours: 2),
          );
        }
        return result;
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('fetchRestaurants network error, trying cache', error: e, stackTrace: stack);
      final cached = await CacheService.getRawJson(_cacheKey);
      if (cached != null && page == 1) {
        final list = jsonDecode(cached) as List;
        final restaurants = list.map((j) => Restaurant.fromJson(j)).toList();
        return RestaurantsPageResult(
          restaurants: restaurants,
          currentPage: 1,
          lastPage: 1,
          total: restaurants.length,
        );
      }
      rethrow;
    }
  }

  Future<RestaurantsPageResult> fetchSearchRestaurantsPage({
    required int page,
    int perPage = 15,
    String? search,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final uri = Uri.parse('${AppConfig.apiUrl}/api/buyer/search/restaurants')
        .replace(queryParameters: query);
    final response = await withRetry(() => http.get(uri, headers: headers));
    if (response.statusCode != 200) {
      throw Exception('Failed to search restaurants: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return _parseRestaurantsPageResult(data, fallbackPage: page);
  }

  // Compatibilidad legacy.
  Future<List<Restaurant>> fetchRestaurants() async {
    final result = await fetchRestaurantsPage(page: 1, perPage: 50);
    return result.restaurants;
  }

  // GET /api/buyer/restaurants/{id} - Obtener detalle de restaurante
  Future<Restaurant> fetchRestaurantDetails(int restaurantId) async {
    if (restaurantId <= 0) {
      throw ArgumentError('restaurantId inválido: $restaurantId');
    }

    final cached = _detailsCache[restaurantId];
    if (cached != null) {
      logger.i('Returning cached details for restaurant ID: $restaurantId');
      return cached;
    }

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
        
        final parsed = Restaurant.fromJson(restaurantData);
        _detailsCache[restaurantId] = parsed;
        return parsed;
      } else if (response.statusCode == 404) {
        throw Exception('Restaurante no encontrado');
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


