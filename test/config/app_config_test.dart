import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/config/env_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('should return correct API URLs', () {
      // Act & Assert
      expect(AppConfig.apiUrlLocal, isNotEmpty);
      expect(AppConfig.apiUrlProd, isNotEmpty);
      expect(AppConfig.apiUrlLocal, contains('localhost'));
      expect(AppConfig.apiUrlProd, contains('api.zonix-eats.com'));
    });

    test('should return correct base URL based on environment', () {
      // Act & Assert
      final baseUrl = AppConfig.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, contains('http'));
    });

    test('should return correct WebSocket URLs', () {
      // Act & Assert
      expect(AppConfig.websocketUrlLocal, isNotEmpty);
      expect(AppConfig.websocketUrlProd, isNotEmpty);
      expect(AppConfig.websocketUrlLocal, contains('ws://'));
      expect(AppConfig.websocketUrlProd, contains('wss://'));
    });

    test('should return correct WebSocket URL based on environment', () {
      // Act & Assert
      final websocketUrl = AppConfig.websocketUrl;
      expect(websocketUrl, isNotEmpty);
      expect(websocketUrl, contains('ws'));
    });

    test('should return correct Echo configuration', () {
      // Act & Assert
      expect(AppConfig.echoAppId, isNotEmpty);
      expect(AppConfig.echoKey, isNotEmpty);
      expect(AppConfig.echoAppId, equals('zonix-eats-app'));
      expect(AppConfig.echoKey, equals('zonix-eats-key'));
    });

    test('should return correct enable WebSockets flag', () {
      // Act & Assert
      expect(AppConfig.enableWebsockets, isTrue);
    });

    test('should return correct Google Maps API Key', () {
      // Act & Assert
      expect(AppConfig.googleMapsApiKey, isNotEmpty);
    });

    test('should return correct Firebase configuration', () {
      // Act & Assert
      expect(AppConfig.firebaseProjectId, isNotEmpty);
      expect(AppConfig.firebaseMessagingSenderId, isNotEmpty);
      expect(AppConfig.firebaseAppId, isNotEmpty);
    });

    test('should return correct app configuration', () {
      // Act & Assert
      expect(AppConfig.appName, equals('ZONIX-EATS'));
      expect(AppConfig.appVersion, equals('1.0.0'));
      expect(AppConfig.appBuildNumber, equals('1'));
    });

    test('should return correct pagination configuration', () {
      // Act & Assert
      expect(AppConfig.defaultPageSize, equals(20));
      expect(AppConfig.maxPageSize, equals(100));
    });

    test('should return correct timeout configuration', () {
      // Act & Assert
      expect(AppConfig.connectionTimeout, equals(30000));
      expect(AppConfig.receiveTimeout, equals(30000));
    });

    test('should return correct retry configuration', () {
      // Act & Assert
      expect(AppConfig.maxRetryAttempts, equals(3));
      expect(AppConfig.retryDelayMs, equals(1000));
    });
  });

  group('EnvConfig Tests', () {
    test('should have correct API URLs', () {
      // Act & Assert
      expect(EnvConfig.apiUrlLocal, equals('http://localhost:8000'));
      expect(EnvConfig.apiUrlProd, equals('https://api.zonix-eats.com'));
    });

    test('should have correct WebSocket URLs', () {
      // Act & Assert
      expect(EnvConfig.websocketUrlLocal, equals('ws://localhost:6001'));
      expect(EnvConfig.websocketUrlProd, equals('wss://echo.zonix-eats.com'));
    });

    test('should have correct Echo configuration', () {
      // Act & Assert
      expect(EnvConfig.echoAppId, equals('zonix-eats-app'));
      expect(EnvConfig.echoKey, equals('zonix-eats-key'));
      expect(EnvConfig.enableWebsockets, isTrue);
    });

    test('should have correct app configuration', () {
      // Act & Assert
      expect(EnvConfig.appName, equals('ZONIX-EATS'));
      expect(EnvConfig.appVersion, equals('1.0.0'));
      expect(EnvConfig.appBuildNumber, equals('1'));
    });

    test('should have correct pagination configuration', () {
      // Act & Assert
      expect(EnvConfig.defaultPageSize, equals(20));
      expect(EnvConfig.maxPageSize, equals(100));
    });

    test('should have correct timeout configuration', () {
      // Act & Assert
      expect(EnvConfig.connectionTimeout, equals(30000));
      expect(EnvConfig.receiveTimeout, equals(30000));
    });

    test('should have correct retry configuration', () {
      // Act & Assert
      expect(EnvConfig.maxRetryAttempts, equals(3));
      expect(EnvConfig.retryDelayMs, equals(1000));
    });

    test('should have correct Google Maps API Key placeholder', () {
      // Act & Assert
      expect(EnvConfig.googleMapsApiKey, equals('your_google_maps_api_key_here'));
    });

    test('should have correct Firebase configuration placeholders', () {
      // Act & Assert
      expect(EnvConfig.firebaseProjectId, equals('your_firebase_project_id'));
      expect(EnvConfig.firebaseMessagingSenderId, equals('your_sender_id'));
      expect(EnvConfig.firebaseAppId, equals('your_app_id'));
    });
  });

  group('Configuration Integration Tests', () {
    test('should use EnvConfig as fallback when environment variables are not set', () {
      // Act & Assert
      expect(AppConfig.apiUrlLocal, equals(EnvConfig.apiUrlLocal));
      expect(AppConfig.apiUrlProd, equals(EnvConfig.apiUrlProd));
      expect(AppConfig.websocketUrlLocal, equals(EnvConfig.websocketUrlLocal));
      expect(AppConfig.websocketUrlProd, equals(EnvConfig.websocketUrlProd));
      expect(AppConfig.echoAppId, equals(EnvConfig.echoAppId));
      expect(AppConfig.echoKey, equals(EnvConfig.echoKey));
      expect(AppConfig.googleMapsApiKey, equals(EnvConfig.googleMapsApiKey));
      expect(AppConfig.firebaseProjectId, equals(EnvConfig.firebaseProjectId));
      expect(AppConfig.firebaseMessagingSenderId, equals(EnvConfig.firebaseMessagingSenderId));
      expect(AppConfig.firebaseAppId, equals(EnvConfig.firebaseAppId));
    });

    test('should have consistent configuration between AppConfig and EnvConfig', () {
      // Act & Assert
      expect(AppConfig.appName, equals(EnvConfig.appName));
      expect(AppConfig.appVersion, equals(EnvConfig.appVersion));
      expect(AppConfig.appBuildNumber, equals(EnvConfig.appBuildNumber));
      expect(AppConfig.defaultPageSize, equals(EnvConfig.defaultPageSize));
      expect(AppConfig.maxPageSize, equals(EnvConfig.maxPageSize));
      expect(AppConfig.connectionTimeout, equals(EnvConfig.connectionTimeout));
      expect(AppConfig.receiveTimeout, equals(EnvConfig.receiveTimeout));
      expect(AppConfig.maxRetryAttempts, equals(EnvConfig.maxRetryAttempts));
      expect(AppConfig.retryDelayMs, equals(EnvConfig.retryDelayMs));
    });

    test('should have valid URL formats', () {
      // Act & Assert
      expect(AppConfig.apiUrlLocal, startsWith('http://'));
      expect(AppConfig.apiUrlProd, startsWith('https://'));
      expect(AppConfig.websocketUrlLocal, startsWith('ws://'));
      expect(AppConfig.websocketUrlProd, startsWith('wss://'));
    });

    test('should have reasonable timeout values', () {
      // Act & Assert
      expect(AppConfig.connectionTimeout, greaterThan(0));
      expect(AppConfig.receiveTimeout, greaterThan(0));
      expect(AppConfig.connectionTimeout, lessThan(60000)); // Less than 1 minute
      expect(AppConfig.receiveTimeout, lessThan(60000)); // Less than 1 minute
    });

    test('should have reasonable retry values', () {
      // Act & Assert
      expect(AppConfig.maxRetryAttempts, greaterThan(0));
      expect(AppConfig.retryDelayMs, greaterThan(0));
      expect(AppConfig.maxRetryAttempts, lessThan(10)); // Less than 10 attempts
      expect(AppConfig.retryDelayMs, lessThan(10000)); // Less than 10 seconds
    });

    test('should have reasonable pagination values', () {
      // Act & Assert
      expect(AppConfig.defaultPageSize, greaterThan(0));
      expect(AppConfig.maxPageSize, greaterThan(AppConfig.defaultPageSize));
      expect(AppConfig.defaultPageSize, lessThan(100)); // Reasonable default
      expect(AppConfig.maxPageSize, lessThan(1000)); // Reasonable max
    });
  });
} 