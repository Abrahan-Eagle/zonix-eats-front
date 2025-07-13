import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/config/app_config.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  group('AppConfig Tests', () {
    test('should return correct API URLs', () {
      expect(AppConfig.apiUrlLocal, isNotEmpty);
      expect(AppConfig.apiUrlProd, isNotEmpty);
    });

    test('should return correct base URL based on environment', () {
      final baseUrl = AppConfig.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl.startsWith('http'), isTrue);
    });

    test('should return correct WebSocket URLs', () {
      expect(AppConfig.websocketUrlLocal, isNotEmpty);
      expect(AppConfig.websocketUrlProd, isNotEmpty);
    });

    test('should return correct WebSocket URL based on environment', () {
      final websocketUrl = AppConfig.websocketUrl;
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

  group('EnvConfig Tests', () {
    test('should have correct API URLs', () {
      expect(AppConfig.apiUrlLocal, equals('http://192.168.0.101:8000'));
      expect(AppConfig.apiUrlProd, equals('https://zonix.uniblockweb.com'));
    });

    test('should have correct WebSocket URLs', () {
      expect(AppConfig.websocketUrlLocal, equals('ws://192.168.0.101:6001'));
      expect(AppConfig.websocketUrlProd, equals('wss://zonix.uniblockweb.com'));
    });

    test('should have correct Echo configuration', () {
      expect(AppConfig.echoAppId, equals('zonix-eats-app'));
      expect(AppConfig.echoKey, equals('zonix-eats-key'));
    });

    test('should have correct enable WebSockets flag', () {
      expect(AppConfig.enableWebsockets, isTrue);
    });

    test('should have correct Google Maps API Key', () {
      expect(AppConfig.googleMapsApiKey, equals('your_google_maps_api_key_here'));
    });

    test('should have correct Firebase configuration', () {
      expect(AppConfig.firebaseProjectId, equals('your_firebase_project_id'));
      expect(AppConfig.firebaseMessagingSenderId, equals('your_sender_id'));
    });
  });

  group('Configuration Integration Tests', () {
    test('should use EnvConfig as fallback when environment variables are not set', () {
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.websocketUrl, isNotEmpty);
      expect(AppConfig.echoAppId, isNotEmpty);
      expect(AppConfig.echoKey, isNotEmpty);
      expect(AppConfig.enableWebsockets, isA<bool>());
      expect(AppConfig.googleMapsApiKey, isNotEmpty);
      expect(AppConfig.firebaseProjectId, isNotEmpty);
      expect(AppConfig.firebaseMessagingSenderId, isNotEmpty);
    });

    test('should have valid URL formats', () {
      final apiUrl = AppConfig.baseUrl;
      final websocketUrl = AppConfig.websocketUrl;
      expect(apiUrl.startsWith('http'), isTrue);
      expect(websocketUrl.startsWith('ws'), isTrue);
      expect(apiUrl.contains('://'), isTrue);
      expect(websocketUrl.contains('://'), isTrue);
    });

    test('should have consistent configuration across environments', () {
      expect(AppConfig.apiUrlLocal.contains('://'), isTrue);
      expect(AppConfig.apiUrlProd.contains('://'), isTrue);
      expect(AppConfig.websocketUrlLocal.contains('://'), isTrue);
      expect(AppConfig.websocketUrlProd.contains('://'), isTrue);
    });
  });
} 