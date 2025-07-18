import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    // Mock dotenv para evitar NotInitializedError
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  });

  group('AppConfig Tests', () {
    test('should return correct API URLs', () {
      expect(AppConfig.apiUrlLocal, isNotEmpty);
      expect(AppConfig.apiUrlProd, isNotEmpty);
    });

    test('should return correct base URL based on environment', () {
      final baseUrl = AppConfig.apiUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl.startsWith('http'), isTrue);
    });

    test('should return correct WebSocket URLs', () {
          expect(AppConfig.wsUrlLocal, isNotEmpty);
    expect(AppConfig.wsUrlProd, isNotEmpty);
    });

    test('should return correct WebSocket URL based on environment', () {
          final websocketUrl = AppConfig.wsUrl;
    expect(websocketUrl, isNotEmpty);
    expect(websocketUrl.startsWith('ws'), isTrue);
    });

    test('should return correct Echo configuration', () {
      expect(AppConfig.echoAppId, isNotEmpty);
      expect(AppConfig.echoKey, isNotEmpty);
    });

    test('should return correct enable WebSockets flag', () {
      expect(AppConfig.enableWebsockets, isA<bool>());
    });

    test('should return correct Google Maps API Key', () {
      expect(AppConfig.googleMapsApiKey, isNotEmpty);
    });

    test('should return correct Firebase configuration', () {
      expect(AppConfig.firebaseProjectId, isNotEmpty);
      expect(AppConfig.firebaseMessagingSenderId, isNotEmpty);
    });
  });

  group('Configuration Integration Tests', () {
    test('should use fallback values when environment variables are not set', () {
      expect(AppConfig.apiUrl, isNotEmpty);
      expect(AppConfig.wsUrl, isNotEmpty);
      expect(AppConfig.echoAppId, isNotEmpty);
      expect(AppConfig.echoKey, isNotEmpty);
      expect(AppConfig.enableWebsockets, isA<bool>());
      expect(AppConfig.googleMapsApiKey, isNotEmpty);
      expect(AppConfig.firebaseProjectId, isNotEmpty);
      expect(AppConfig.firebaseMessagingSenderId, isNotEmpty);
    });

    test('should have valid URL formats', () {
      final apiUrl = AppConfig.apiUrl;
      final websocketUrl = AppConfig.wsUrl;
      expect(apiUrl.startsWith('http'), isTrue);
      expect(websocketUrl.startsWith('ws'), isTrue);
      expect(apiUrl.contains('://'), isTrue);
      expect(websocketUrl.contains('://'), isTrue);
    });
  });
} 