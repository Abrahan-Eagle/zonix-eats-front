import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración central de la app. Todas las URLs y credenciales se leen desde .env.
class AppConfig {
  static bool get _isProduction =>
      const bool.fromEnvironment('dart.vm.product', defaultValue: false);

  // API URLs (desde .env: API_URL o API_URL_LOCAL / API_URL_PROD)
  static String get apiUrl {
    final override = dotenv.env['API_URL'];
    if (override != null && override.isNotEmpty) return override;
    return _isProduction
        ? (dotenv.env['API_URL_PROD'] ?? '')
        : (dotenv.env['API_URL_LOCAL'] ?? '');
  }

  // WebSocket / legacy (desde .env; tiempo real real usa Pusher)
  static String get wsUrl {
    final override = dotenv.env['WS_URL'];
    if (override != null && override.isNotEmpty) return override;
    return _isProduction
        ? (dotenv.env['WS_URL_PROD'] ?? '')
        : (dotenv.env['WS_URL_LOCAL'] ?? '');
  }

  /// Tiempo real: true para usar Pusher (notificaciones, chat, órdenes).
  static bool get enablePusher =>
      dotenv.env['ENABLE_PUSHER']?.toLowerCase() == 'true';

  static bool get enableWebsockets =>
      dotenv.env['ENABLE_WEBSOCKETS']?.toLowerCase() == 'true';

  // Google Maps (desde .env)
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Firebase (desde .env)
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // App info (desde .env o constantes por defecto)
  static String get appName => dotenv.env['APP_NAME'] ?? 'Zonix Eats';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appBuildNumber =>
      dotenv.env['APP_BUILD_NUMBER'] ?? '1';

  // Timeouts (desde .env, en ms)
  static int get connectionTimeout =>
      int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '') ?? 30000;
  static int get receiveTimeout =>
      int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '') ?? 30000;
  static int get requestTimeout =>
      int.tryParse(dotenv.env['REQUEST_TIMEOUT'] ?? '') ?? 30000;

  // Reintentos
  static int get maxRetryAttempts =>
      int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '') ?? 3;
  static int get retryDelayMs =>
      int.tryParse(dotenv.env['RETRY_DELAY_MS'] ?? '') ?? 1000;

  // Paginación
  static int get defaultPageSize =>
      int.tryParse(dotenv.env['DEFAULT_PAGE_SIZE'] ?? '') ?? 20;
  static int get maxPageSize =>
      int.tryParse(dotenv.env['MAX_PAGE_SIZE'] ?? '') ?? 100;
}
