import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/location_service.dart';

void main() {
  late LocationService locationService;

  setUp(() {
    locationService = LocationService();
  });

  group('LocationService Tests', () {
    test('calculateDistance should return correct distance using Haversine formula', () {
      // Lima, Perú coordinates
      double lat1 = -12.0464;
      double lon1 = -77.0428;
      
      // Arequipa, Perú coordinates (aproximadamente 766 km al sur)
      double lat2 = -16.4090;
      double lon2 = -71.5375;
      
      double distance = locationService.calculateDistance(lat1, lon1, lat2, lon2);
      
      // La distancia entre Lima y Arequipa es aproximadamente 766 km
      expect(distance, greaterThan(700));
      expect(distance, lessThan(800));
    });

    test('calculateDistance should return 0 for same coordinates', () {
      double lat = -12.0464;
      double lon = -77.0428;
      
      double distance = locationService.calculateDistance(lat, lon, lat, lon);
      
      expect(distance, equals(0));
    });

    test('formatDistance should format distance correctly', () {
      expect(locationService.formatDistance(0.5), equals('500 m'));
      expect(locationService.formatDistance(1.0), equals('1.0 km'));
      expect(locationService.formatDistance(5.5), equals('5.5 km'));
    });

    test('formatTime should format time correctly', () {
      expect(locationService.formatTime(30), equals('30 min'));
      expect(locationService.formatTime(60), equals('1 h 0 min'));
      expect(locationService.formatTime(90), equals('1 h 30 min'));
    });

    test('isLocationInDeliveryZone should return true when location is within zone', () {
      Map<String, dynamic> zone = {
        'center': {'latitude': -12.0464, 'longitude': -77.0428},
        'radius': 5.0, // 5 km
      };
      
      // Ubicación dentro de la zona (1 km del centro)
      bool isInZone = locationService.isLocationInDeliveryZone(
        -12.0464,
        -77.0428,
        zone,
      );
      
      expect(isInZone, isTrue);
    });

    test('isLocationInDeliveryZone should return false when location is outside zone', () {
      Map<String, dynamic> zone = {
        'center': {'latitude': -12.0464, 'longitude': -77.0428},
        'radius': 1.0, // 1 km
      };
      
      // Ubicación fuera de la zona (10 km del centro)
      bool isInZone = locationService.isLocationInDeliveryZone(
        -12.1364,
        -77.1328,
        zone,
      );
      
      expect(isInZone, isFalse);
    });

    test('getNearestDeliveryZone should return nearest active zone', () {
      List<Map<String, dynamic>> zones = [
        {
          'id': 1,
          'center': {'latitude': -12.0464, 'longitude': -77.0428},
          'radius': 5.0,
          'is_active': true,
        },
        {
          'id': 2,
          'center': {'latitude': -12.0564, 'longitude': -77.0528},
          'radius': 7.0,
          'is_active': true,
        },
        {
          'id': 3,
          'center': {'latitude': -12.0664, 'longitude': -77.0628},
          'radius': 3.0,
          'is_active': false,
        },
      ];
      
      Map<String, dynamic>? nearestZone = locationService.getNearestDeliveryZone(
        -12.0464,
        -77.0428,
        zones,
      );
      
      expect(nearestZone, isNotNull);
      expect(nearestZone!['id'], equals(1));
    });

    test('getNearestDeliveryZone should return null for empty zones list', () {
      Map<String, dynamic>? nearestZone = locationService.getNearestDeliveryZone(
        -12.0464,
        -77.0428,
        [],
      );
      
      expect(nearestZone, isNull);
    });
  });
}
