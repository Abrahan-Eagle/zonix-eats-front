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

  // Delivery: tarifa por defecto (idealmente el backend la calcula por zona; aquí solo fallback para UI)
  static double get defaultDeliveryFee =>
      double.tryParse(dotenv.env['DEFAULT_DELIVERY_FEE'] ?? '') ?? 2.50;

  // Mapas y geocoding (sin hardcode en pantallas)
  static String get osmTileUrl =>
      dotenv.env['OSM_TILE_URL'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static String get nominatimReverseUrl =>
      dotenv.env['NOMINATIM_REVERSE_URL'] ?? 'https://nominatim.openstreetmap.org/reverse';
  static String get nominatimSearchUrl =>
      dotenv.env['NOMINATIM_SEARCH_URL'] ?? 'https://nominatim.openstreetmap.org/search';
  static String get googleMapsDirUrl =>
      dotenv.env['GOOGLE_MAPS_DIR_URL'] ?? 'https://www.google.com/maps/dir/?api=1';
  static String get googleMapsSearchUrl =>
      dotenv.env['GOOGLE_MAPS_SEARCH_URL'] ?? 'https://www.google.com/maps/search/?api=1';
  /// Base URL para abrir un punto en Google Maps: ?q=lat,lng
  static String get googleMapsPointUrl =>
      dotenv.env['GOOGLE_MAPS_POINT_URL'] ?? 'https://www.google.com/maps?q';
  static String get openStreetMapViewUrl =>
      dotenv.env['OPENSTREETMAP_VIEW_URL'] ?? 'https://www.openstreetmap.org';
  /// Base URL para abrir chat WhatsApp (ej. https://wa.me)
  static String get whatsappBaseUrl =>
      dotenv.env['WHATSAPP_BASE_URL'] ?? 'https://wa.me';

  static String get supportUrl =>
      dotenv.env['SUPPORT_URL'] ?? 'https://zonixeats.com/soporte';
  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? 'soporte@zonixeats.com';

  /// Base pública para enlaces compartibles (HTTPS `.../r/{commerceId}`).
  /// Resolución alineada a entornos (local / tests / producción), igual que [apiUrl]:
  /// 1) `APP_LINK_BASE` si está definido (override para cualquier entorno)
  /// 2) Según `ENVIRONMENT`: `development|local|dev` → `APP_LINK_BASE_LOCAL` o `APP_LINK_BASE_DEV`;
  ///    `staging|test|testing` → `APP_LINK_BASE_STAGING` o `APP_LINK_BASE_TEST`;
  ///    `production|prod` → `APP_LINK_BASE_PROD`
  /// 3) Build release (`dart.vm.product`): `APP_LINK_BASE_PROD` si existe
  /// 4) Fallback: `APP_LINK_BASE_LOCAL` / `APP_LINK_BASE_DEV`
  /// 5) Legacy: `PUBLIC_LINK_BASE`
  /// Si todo queda vacío, [buildCommerceShareUrl] usa solo el deep link `zonix://`.
  static String get appLinkBase {
    final override = dotenv.env['APP_LINK_BASE']?.trim();
    if (override != null && override.isNotEmpty) return override;

    final env =
        (dotenv.env['ENVIRONMENT'] ?? 'development').toLowerCase().trim();

    if (env == 'production' || env == 'prod') {
      final p = dotenv.env['APP_LINK_BASE_PROD']?.trim();
      if (p != null && p.isNotEmpty) return p;
    }
    if (env == 'staging' ||
        env == 'test' ||
        env == 'testing' ||
        env == 'qa') {
      final s = dotenv.env['APP_LINK_BASE_STAGING']?.trim() ??
          dotenv.env['APP_LINK_BASE_TEST']?.trim();
      if (s != null && s.isNotEmpty) return s;
    }
    if (env == 'development' ||
        env == 'local' ||
        env == 'dev') {
      final d = dotenv.env['APP_LINK_BASE_LOCAL']?.trim() ??
          dotenv.env['APP_LINK_BASE_DEV']?.trim();
      if (d != null && d.isNotEmpty) return d;
    }

    if (_isProduction) {
      final p = dotenv.env['APP_LINK_BASE_PROD']?.trim();
      if (p != null && p.isNotEmpty) return p;
    }

    final local = dotenv.env['APP_LINK_BASE_LOCAL']?.trim() ??
        dotenv.env['APP_LINK_BASE_DEV']?.trim();
    if (local != null && local.isNotEmpty) return local;

    return (dotenv.env['PUBLIC_LINK_BASE'] ?? '').trim();
  }

  /// Payload QR obligatorio en app: `zonix://restaurant/{commerceId}`.
  static String buildCommerceDeepLink(int commerceId) =>
      'zonix://restaurant/$commerceId';

  /// URL para compartir (HTTPS si [appLinkBase] está definido; si no, el mismo deep link).
  static String buildCommerceShareUrl(int commerceId) {
    final base = appLinkBase;
    if (base.isEmpty) return buildCommerceDeepLink(commerceId);
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$b/r/$commerceId';
  }
}
