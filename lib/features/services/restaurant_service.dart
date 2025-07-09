

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../models/restaurant.dart';

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class RestaurantService {
  final String apiUrl = '$baseUrl/api/buyer/restaurants';
  final storage = const FlutterSecureStorage();
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  Future<String?> _getToken() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        logger.w('Token not found in secure storage');
      } else {
        logger.v('Token retrieved successfully');
      }
      return token;
    } catch (e, stack) {
      logger.e('Error retrieving token',
          error: e,
          stackTrace: stack);
      throw Exception('Authentication token retrieval failed');
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    logger.i('Fetching restaurants list');
    
    String? token = await _getToken();

    if (token == null) {
      logger.e('No authentication token available');
      throw Exception('Authentication required. Please login.');
    }

    try {
      logger.d('Making GET request to: $apiUrl');
      logger.d('Making GET request to: $token');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      logger.i('API Response', 
          error: 'Status: ${response.statusCode}',
          stackTrace: StackTrace.current);

      logger.i('API Response Status x: ${response.statusCode}');

      if (response.statusCode == 200) {
        logger.d('Processing successful response');
        List<dynamic> data = jsonDecode(response.body);

        // logger.i('API Response Status xxxxxx: ${response.body}');
        
        if (data.isNotEmpty) {
          logger.i('Successfully mapped ${data.length} restaurants');
          // logger.i('Successfully mapped ${data.toString()} restaurants');
          return data.map((json) => Restaurant.fromJson(json)).toList();
        } else {
          logger.w('Empty restaurants list received');
          return [];
        }
      } else {
        logger.e('API Error Response',
            error: 'Status: ${response.statusCode}, Body: ${response.body}',
            stackTrace: StackTrace.current);
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('Exception in fetchRestaurants',
          error: e,
          stackTrace: stack);
      throw Exception('Restaurants fetch failed: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRestaurantDetails(int restaurantId) async {
    logger.i('Fetching details for restaurant ID: $restaurantId');
    
    String? token = await _getToken();

    if (token == null) {
      logger.e('No authentication token available for details request');
      throw Exception('Authentication required. Please login.');
    }

    try {
      final url = '$apiUrl/details/$restaurantId';
      logger.d('Making GET request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      logger.i('API Details Response',
          error: 'Status: ${response.statusCode}',
          stackTrace: StackTrace.current);

      if (response.statusCode == 200) {
        logger.d('Processing restaurant details');
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        logger.e('API Details Error',
            error: 'Status: ${response.statusCode}, Body: ${response.body}',
            stackTrace: StackTrace.current);
        throw Exception('Failed to load details: ${response.statusCode}');
      }
    } catch (e, stack) {
      logger.e('Exception in fetchRestaurantDetails',
          error: e,
          stackTrace: stack);
      throw Exception('Details fetch failed: ${e.toString()}');
    }
  }



  Future<Restaurant> fetchRestaurantDetails2(int commerceId) async {
    logger.i('Fetching details for restaurant ID: $commerceId');

        
    String? token = await _getToken();

    if (token == null) {
      logger.e('No authentication token available for details request');
      throw Exception('Authentication required. Please login.');
    }




  try {

      final url = '$apiUrl/$commerceId';
      logger.d('Making GET request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      logger.i('API Details Response',
          error: 'Status: ${response.statusCode}',
          stackTrace: StackTrace.current);
      logger.d('Response Body: ${response.body}');
      logger.d('Response Headers: ${response.headers}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Si la API devuelve una lista, toma el primer elemento
      if (data is List) {
        if (data.isNotEmpty) {
          return Restaurant.fromJson(data[0]); // Asume que el primero es el correcto
        } else {
          throw Exception('No se encontró el restaurante');
        }
      } 
      // Si la API devuelve un objeto directo
      else if (data is Map<String, dynamic>) {
        return Restaurant.fromJson(data);
      } else {
        throw Exception('Formato de respuesta inválido');
      }
    } else {
      throw Exception('Error al cargar el restaurante');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}
}


