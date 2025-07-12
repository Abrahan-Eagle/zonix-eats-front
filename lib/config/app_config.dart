import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env_config.dart';

class AppConfig {
  // API URLs
  static String get apiUrlLocal => dotenv.env['API_URL_LOCAL'] ?? EnvConfig.apiUrlLocal;
  static String get apiUrlProd => dotenv.env['API_URL_PROD'] ?? EnvConfig.apiUrlProd;
  static String get baseUrl => const bool.fromEnvironment('dart.vm.product') ? apiUrlProd : apiUrlLocal;

  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? EnvConfig.googleMapsApiKey;

  // WebSocket Configuration - Laravel Echo Server
  static String get websocketUrlLocal => dotenv.env['WEBSOCKET_URL_LOCAL'] ?? EnvConfig.websocketUrlLocal;
  static String get websocketUrlProd => dotenv.env['WEBSOCKET_URL_PROD'] ?? EnvConfig.websocketUrlProd;
  static String get websocketUrl => const bool.fromEnvironment('dart.vm.product') ? websocketUrlProd : websocketUrlLocal;
  
  static String get echoAppId => dotenv.env['ECHO_APP_ID'] ?? EnvConfig.echoAppId;
  static String get echoKey => dotenv.env['ECHO_KEY'] ?? EnvConfig.echoKey;
  static bool get enableWebsockets => dotenv.env['ENABLE_WEBSOCKETS'] == 'true' || EnvConfig.enableWebsockets;

  // Firebase Configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? EnvConfig.firebaseProjectId;
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? EnvConfig.firebaseMessagingSenderId;
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? EnvConfig.firebaseAppId;

  // App Configuration
  static String get appName => EnvConfig.appName;
  static String get appVersion => EnvConfig.appVersion;
  static String get appBuildNumber => EnvConfig.appBuildNumber;

  // Pagination Configuration
  static int get defaultPageSize => EnvConfig.defaultPageSize;
  static int get maxPageSize => EnvConfig.maxPageSize;

  // Timeout Configuration
  static int get connectionTimeout => EnvConfig.connectionTimeout;
  static int get receiveTimeout => EnvConfig.receiveTimeout;

  // Retry Configuration
  static int get maxRetryAttempts => EnvConfig.maxRetryAttempts;
  static int get retryDelayMs => EnvConfig.retryDelayMs;
} 