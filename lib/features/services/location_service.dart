import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class LocationService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  Timer? _locationTimer;
  StreamController<Map<String, dynamic>>? _locationController;

  // Get current location using geolocator
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Verificar permisos de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Obtener dirección usando Nominatim (geocodificación inversa)
      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp.toIso8601String(),
        'address': address,
      };
    } catch (e) {
      debugPrint('Error getting current location: $e');
      rethrow;
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
        debugPrint('Error tracking location: $e');
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
      final headers = await AuthHelper.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/location/update'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'accuracy': location['accuracy'],
          'altitude': location['altitude'],
          'speed': location['speed'],
          'heading': location['heading'],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error updating location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  // Get nearby places
  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse('$baseUrl/api/location/nearby-places').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Error getting nearby places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting nearby places: $e');
    }
  }

  // Get delivery routes
  Future<List<Map<String, dynamic>>> getDeliveryRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/location/delivery-routes'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener delivery routes: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
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

  // Get address from coordinates using Nominatim (OpenStreetMap)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': '${AppConfig.appName} App',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        
        if (address != null) {
          final parts = <String>[];
          
          // Construir dirección legible
          if (address['house_number'] != null) {
            parts.add(address['house_number']);
          }
          if (address['road'] != null) {
            parts.add(address['road']);
          }
          if (address['suburb'] != null || address['neighbourhood'] != null) {
            parts.add(address['suburb'] ?? address['neighbourhood']);
          }
          if (address['city'] != null || address['town'] != null || address['village'] != null) {
            parts.add(address['city'] ?? address['town'] ?? address['village']);
          }
          if (address['state'] != null) {
            parts.add(address['state']);
          }
          if (address['country'] != null) {
            parts.add(address['country']);
          }
          
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
          
          // Fallback: usar display_name si está disponible
          if (data['display_name'] != null) {
            return data['display_name'];
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error en geocodificación inversa: $e');
      return null;
    }
  }

  // Get coordinates from address using Nominatim (OpenStreetMap)
  Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&addressdetails=1',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': '${AppConfig.appName} App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data != null && data is List && data.isNotEmpty) {
          final result = data[0];
          return {
            'latitude': double.parse(result['lat']),
            'longitude': double.parse(result['lon']),
          };
        }
      }
      
      throw Exception('No se encontraron coordenadas para la dirección: $address');
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      rethrow;
    }
  }

  // Calculate route between two points
  Future<Map<String, dynamic>> calculateRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String mode = 'driving',
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/location/calculate-route'),
        headers: headers,
        body: jsonEncode({
          'origin_lat': originLat,
          'origin_lng': originLng,
          'destination_lat': destinationLat,
          'destination_lng': destinationLng,
          'mode': mode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception('Error calculating route: Invalid response');
        }
      } else {
        throw Exception('Error calculating route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calculating route: $e');
    }
  }

  // Get delivery zones
  Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/location/delivery-zones'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Error getting delivery zones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting delivery zones: $e');
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
      return '$hours h $remainingMinutes min';
    }
  }
} 