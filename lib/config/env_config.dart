// Configuración de entorno para ZONIX-EATS
// Este archivo contiene las variables de entorno por defecto
// En producción, estas variables deben estar en un archivo .env

class EnvConfig {
  // API URLs
  static const String apiUrlLocal = 'http://192.168.0.101:8000';
  static const String apiUrlProd = 'https://zonix.uniblockweb.com';
  
  // Google Maps API Key
  static const String googleMapsApiKey = 'your_google_maps_api_key_here';
  
  // WebSocket Configuration - Laravel Echo Server
  static const String websocketUrlLocal = 'ws://192.168.0.101:6001';
  static const String websocketUrlProd = 'wss://zonix.uniblockweb.com';
  static const String echoAppId = 'zonix-eats-app';
  static const String echoKey = 'zonix-eats-key';
  static const bool enableWebsockets = true;
  
  // Firebase Configuration (si usas notificaciones push)
  static const String firebaseProjectId = 'your_firebase_project_id';
  static const String firebaseMessagingSenderId = 'your_sender_id';
  static const String firebaseAppId = 'your_app_id';
  
  // Configuración de la aplicación
  static const String appName = 'ZONIX-EATS';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Configuración de timeouts
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
  
  // Configuración de reintentos
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000; // 1 segundo
} 