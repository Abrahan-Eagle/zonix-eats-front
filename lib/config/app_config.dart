import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API URLs
  static String get apiUrlLocal => dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000';
  static String get apiUrlProd => dotenv.env['API_URL_PROD'] ?? 'https://api.zonix-eats.com';
  static String get baseUrl => const bool.fromEnvironment('dart.vm.product') ? apiUrlProd : apiUrlLocal;

  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // WebSocket Configuration
  static String get websocketUrlLocal => dotenv.env['WEBSOCKET_URL_LOCAL'] ?? 'ws://localhost:6001';
  static String get websocketUrlProd => dotenv.env['WEBSOCKET_URL_PROD'] ?? 'wss://echo.zonix-eats.com';
  static String get websocketUrl => const bool.fromEnvironment('dart.vm.product') ? websocketUrlProd : websocketUrlLocal;

  // Payment Gateway Keys (Stripe)
  static String get stripePublishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  // Firebase Configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Zonix Eats';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appBuildNumber => dotenv.env['APP_BUILD_NUMBER'] ?? '1';

  // Feature Flags
  static bool get enablePushNotifications => dotenv.env['ENABLE_PUSH_NOTIFICATIONS'] == 'true';
  static bool get enableRealTimeTracking => dotenv.env['ENABLE_REAL_TIME_TRACKING'] == 'true';
  static bool get enableAnalytics => dotenv.env['ENABLE_ANALYTICS'] == 'true';
  static bool get enableChat => dotenv.env['ENABLE_CHAT'] == 'true';

  // API Endpoints
  static String get authEndpoint => '$baseUrl/api/auth';
  static String get notificationsEndpoint => '$baseUrl/api/notifications';
  static String get paymentEndpoint => '$baseUrl/api/payment';
  static String get chatEndpoint => '$baseUrl/api/chat';
  static String get analyticsEndpoint => '$baseUrl/api/analytics';
  static String get locationEndpoint => '$baseUrl/api/location';
  static String get deliveryEndpoint => '$baseUrl/api/delivery';
  static String get commerceEndpoint => '$baseUrl/api/commerce';
  static String get affiliateEndpoint => '$baseUrl/api/affiliate';
  static String get adminEndpoint => '$baseUrl/api/admin';
  static String get transportEndpoint => '$baseUrl/api/transport';
} 