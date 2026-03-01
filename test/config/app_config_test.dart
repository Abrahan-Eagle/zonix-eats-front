import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '''
API_URL_LOCAL=http://localhost:8000
API_URL_PROD=https://example.com
WS_URL_LOCAL=ws://localhost:6001
WS_URL_PROD=wss://example.com
ENABLE_PUSHER=true
ENABLE_WEBSOCKETS=false
GOOGLE_MAPS_API_KEY=test_key
FIREBASE_PROJECT_ID=test_project
FIREBASE_MESSAGING_SENDER_ID=test_sender
''');
    }
  });

  group('AppConfig Tests', () {
    test('should return correct base URL based on environment', () {
      final baseUrl = AppConfig.apiUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl.startsWith('http'), isTrue);
    });

    test('should return correct WebSocket URL based on environment', () {
      final websocketUrl = AppConfig.wsUrl;
      expect(websocketUrl, isNotEmpty);
      expect(websocketUrl.startsWith('ws'), isTrue);
    });

    test('should return correct enable WebSockets flag', () {
      expect(AppConfig.enableWebsockets, isA<bool>());
    });

    test('should return correct enable Pusher flag', () {
      expect(AppConfig.enablePusher, isA<bool>());
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
    test('should use apiUrl and wsUrl from env', () {
      expect(AppConfig.apiUrl, isNotEmpty);
      expect(AppConfig.wsUrl, isNotEmpty);
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
