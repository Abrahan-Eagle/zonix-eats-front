import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
  Timer? _locationTimer;
  StreamController<Map<String, dynamic>>? _locationController;
  
  // Mock data for development
  static final Map<String, dynamic> _mockCurrentLocation = {
    'latitude': -12.0464,
    'longitude': -77.0428,
    'accuracy': 10.0,
    'altitude': 150.0,
    'speed': 25.5,
    'heading': 180.0,
    'timestamp': DateTime.now().toIso8601String(),
    'address': 'Lima, Perú',
  };

  static final List<Map<String, dynamic>> _mockNearbyPlaces = [
    {
      'id': 1,
      'name': 'Restaurante El Buen Sabor',
      'type': 'restaurant',
      'latitude': -12.0465,
      'longitude': -77.0429,
      'distance': 0.1,
      'rating': 4.5,
      'address': 'Av. Arequipa 123, Lima',
      'phone': '+51 123 456 789',
      'is_open': true,
    },
    {
      'id': 2,
      'name': 'Pizzería La Italiana',
      'type': 'restaurant',
      'latitude': -12.0463,
      'longitude': -77.0427,
      'distance': 0.2,
      'rating': 4.3,
      'address': 'Jr. Tacna 456, Lima',
      'phone': '+51 987 654 321',
      'is_open': true,
    },
    {
      'id': 3,
      'name': 'Café Central',
      'type': 'cafe',
      'latitude': -12.0466,
      'longitude': -77.0430,
      'distance': 0.3,
      'rating': 4.7,
      'address': 'Plaza Mayor 789, Lima',
      'phone': '+51 456 789 123',
      'is_open': false,
    },
  ];

  static final List<Map<String, dynamic>> _mockDeliveryRoutes = [
    {
      'id': 1,
      'order_id': 123,
      'start_location': {
        'latitude': -12.0464,
        'longitude': -77.0428,
        'address': 'Restaurante El Buen Sabor',
      },
      'end_location': {
        'latitude': -12.0470,
        'longitude': -77.0435,
        'address': 'Av. Arequipa 500, Lima',
      },
      'distance': 0.8,
      'estimated_time': 15,
      'waypoints': [
        {'latitude': -12.0467, 'longitude': -77.0431},
        {'latitude': -12.0469, 'longitude': -77.0433},
      ],
    },
    {
      'id': 2,
      'order_id': 124,
      'start_location': {
        'latitude': -12.0464,
        'longitude': -77.0428,
        'address': 'Pizzería La Italiana',
      },
      'end_location': {
        'latitude': -12.0450,
        'longitude': -77.0410,
        'address': 'Jr. Tacna 200, Lima',
      },
      'distance': 1.2,
      'estimated_time': 20,
      'waypoints': [
        {'latitude': -12.0457, 'longitude': -77.0419},
        {'latitude': -12.0453, 'longitude': -77.0415},
      ],
    },
  ];

  // Get current location
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // TODO: Replace with real GPS/geolocation call
      // final position = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.high,
      // );
      // return {
      //   'latitude': position.latitude,
      //   'longitude': position.longitude,
      //   'accuracy': position.accuracy,
      //   'altitude': position.altitude,
      //   'speed': position.speed,
      //   'heading': position.heading,
      //   'timestamp': position.timestamp?.toIso8601String(),
      // };
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 1000));
      return _mockCurrentLocation;
    } catch (e) {
      throw Exception('Error getting current location: $e');
    }
  }

  // Start location tracking
  void startLocationTracking({int intervalSeconds = 30}) {
    _locationController = StreamController<Map<String, dynamic>>.broadcast();
    
    _locationTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        final location = await getCurrentLocation();
        _locationController?.add(location);
        
        // Update location on server
        await updateLocationOnServer(location);
      } catch (e) {
        print('Error tracking location: $e');
      }
    });
  }

  // Stop location tracking
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationController?.close();
    _locationTimer = null;
    _locationController = null;
  }

  // Get location stream
  Stream<Map<String, dynamic>>? get locationStream {
    return _locationController?.stream;
  }

  // Update location on server
  Future<void> updateLocationOnServer(Map<String, dynamic> location) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/api/location/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(location),
      );

      if (response.statusCode == 200) {
        print('Location updated on server: ${location['latitude']}, ${location['longitude']}');
      } else {
        // Fallback to mock data
        await Future.delayed(Duration(milliseconds: 300));
        print('Location updated on server: ${location['latitude']}, ${location['longitude']}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 300));
      print('Location updated on server: ${location['latitude']}, ${location['longitude']}');
    }
  }

  // Get nearby places
  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    double? latitude,
    double? longitude,
    double radius = 1.0,
    String? type,
  }) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/places/nearby', {
      //   'latitude': latitude ?? _mockCurrentLocation['latitude'],
      //   'longitude': longitude ?? _mockCurrentLocation['longitude'],
      //   'radius': radius,
      //   'type': type,
      // });
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 800));
      var places = _mockNearbyPlaces;
      
      if (type != null) {
        places = places.where((p) => p['type'] == type).toList();
      }
      
      return places;
    } catch (e) {
      throw Exception('Error fetching nearby places: $e');
    }
  }

  // Get delivery routes
  Future<List<Map<String, dynamic>>> getDeliveryRoutes() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/routes');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return _mockDeliveryRoutes;
    } catch (e) {
      throw Exception('Error fetching delivery routes: $e');
    }
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double lat1Rad = _degreesToRadians(lat1);
    double lat2Rad = _degreesToRadians(lat2);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad);
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // TODO: Replace with real geocoding API call
      // final response = await _apiService.get('/geocoding/reverse', {
      //   'latitude': latitude,
      //   'longitude': longitude,
      // });
      // return response['data']['address'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return 'Av. Arequipa ${(latitude * 1000).round()}, Lima, Perú';
    } catch (e) {
      throw Exception('Error getting address: $e');
    }
  }

  // Get coordinates from address
  Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    try {
      // TODO: Replace with real geocoding API call
      // final response = await _apiService.get('/geocoding/forward', {
      //   'address': address,
      // });
      // return {
      //   'latitude': response['data']['latitude'],
      //   'longitude': response['data']['longitude'],
      // };
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'latitude': -12.0464 + (address.hashCode % 100) / 10000,
        'longitude': -77.0428 + (address.hashCode % 100) / 10000,
      };
    } catch (e) {
      throw Exception('Error getting coordinates: $e');
    }
  }

  // Calculate route between two points
  Future<Map<String, dynamic>> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String mode = 'driving',
  }) async {
    try {
      // TODO: Replace with real routing API call
      // final response = await _apiService.get('/routing/calculate', {
      //   'start_lat': startLat,
      //   'start_lon': startLon,
      //   'end_lat': endLat,
      //   'end_lon': endLon,
      //   'mode': mode,
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 1000));
      final distance = calculateDistance(startLat, startLon, endLat, endLon);
      final estimatedTime = (distance * 2).round(); // Rough estimate: 2 min per km
      
      return {
        'distance': distance,
        'estimated_time': estimatedTime,
        'waypoints': [
          {
            'latitude': (startLat + endLat) / 2,
            'longitude': (startLon + endLon) / 2,
          },
        ],
        'polyline': 'mock_polyline_data',
        'mode': mode,
      };
    } catch (e) {
      throw Exception('Error calculating route: $e');
    }
  }

  // Get delivery zones
  Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/zones');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return [
        {
          'id': 1,
          'name': 'Zona Centro',
          'center': {'latitude': -12.0464, 'longitude': -77.0428},
          'radius': 5.0,
          'delivery_fee': 2.0,
          'estimated_time': 30,
          'is_active': true,
        },
        {
          'id': 2,
          'name': 'Zona Norte',
          'center': {'latitude': -12.0400, 'longitude': -77.0400},
          'radius': 3.0,
          'delivery_fee': 3.5,
          'estimated_time': 45,
          'is_active': true,
        },
        {
          'id': 3,
          'name': 'Zona Sur',
          'center': {'latitude': -12.0500, 'longitude': -77.0500},
          'radius': 4.0,
          'delivery_fee': 2.5,
          'estimated_time': 40,
          'is_active': false,
        },
      ];
    } catch (e) {
      throw Exception('Error fetching delivery zones: $e');
    }
  }

  // Check if location is within delivery zone
  bool isLocationInDeliveryZone(
    double latitude,
    double longitude,
    Map<String, dynamic> zone,
  ) {
    final zoneCenter = zone['center'];
    final distance = calculateDistance(
      latitude,
      longitude,
      zoneCenter['latitude'],
      zoneCenter['longitude'],
    );
    
    return distance <= zone['radius'];
  }

  // Get nearest delivery zone
  Map<String, dynamic>? getNearestDeliveryZone(
    double latitude,
    double longitude,
    List<Map<String, dynamic>> zones,
  ) {
    if (zones.isEmpty) return null;
    
    Map<String, dynamic> nearestZone = zones.first;
    double minDistance = double.infinity;
    
    for (final zone in zones) {
      if (!zone['is_active']) continue;
      
      final zoneCenter = zone['center'];
      final distance = calculateDistance(
        latitude,
        longitude,
        zoneCenter['latitude'],
        zoneCenter['longitude'],
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestZone = zone;
      }
    }
    
    return nearestZone;
  }

  // Format distance for display
  String formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  // Format time for display
  String formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes} min';
    }
  }
} 