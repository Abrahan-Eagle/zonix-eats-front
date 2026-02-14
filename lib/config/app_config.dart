import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API URLs
  static const String apiUrlLocal = 'http://192.168.27.12:8000';
  static const String apiUrlProd = 'https://zonix.uniblockweb.com';

  static String get apiUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? apiUrlProd : apiUrlLocal;
  }

  // WebSocket Configuration - Laravel Echo Server
  static const String wsUrlLocal = 'ws://192.168.27.12:6001';
  static const String wsUrlProd = 'wss://zonix.uniblockweb.com';

  static String get wsUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? wsUrlProd : wsUrlLocal;
  }

  // Echo Server Configuration
  static const String echoAppId = 'zonix-eats-app';
  static const String echoKey = 'zonix-eats-key';
  static const bool enableWebsockets = true;

  // Google Maps API Key
  static const String googleMapsApiKey = 'your_google_maps_api_key_here';

  // Firebase Configuration (si usas notificaciones push)
  static const String firebaseProjectId = 'your_firebase_project_id';
  static const String firebaseMessagingSenderId = 'your_sender_id';
  static const String firebaseAppId = 'your_app_id';

  // Configuración de la aplicación
  static const String appName = 'Zonix Eats';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuración de timeouts
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
  static const int requestTimeout = 30000; // 30 segundos

  // Configuración de reintentos
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000; // 1 segundo
}
