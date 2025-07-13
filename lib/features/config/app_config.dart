import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String apiUrlLocal = 'http://192.168.0.101:8000';
  static const String apiUrlProd = 'https://api.zonix-eats.com';
  
  static String get apiUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? apiUrlProd : apiUrlLocal;
  }
  
  static const String wsUrlLocal = 'ws://192.168.0.101:6001';
  static const String wsUrlProd = 'wss://ws.zonix-eats.com';
  
  static String get wsUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? wsUrlProd : wsUrlLocal;
  }
  
  // Configuración de la aplicación
  static const String appName = 'Zonix Eats';
  static const String appVersion = '1.0.0';
  
  // Configuración de paginación
  static const int defaultPageSize = 20;
  
  // Configuración de timeouts
  static const int requestTimeout = 30000; // 30 segundos
  static const int connectionTimeout = 10000; // 10 segundos
} 