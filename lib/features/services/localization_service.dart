import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class LocalizationService {
  static String get baseUrl => AppConfig.baseUrl;
  static int get requestTimeout => AppConfig.requestTimeout;

  /// Obtener idiomas disponibles
  static Future<Map<String, dynamic>> getAvailableLanguages() async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/languages'),
        headers: headers,
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener idiomas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener traducciones para un idioma
  static Future<Map<String, dynamic>> getTranslations(String language) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/translations?language=$language'),
        headers: headers,
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener traducciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener configuración regional
  static Future<Map<String, dynamic>> getRegionalSettings(String language) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/regional-settings?language=$language'),
        headers: headers,
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener configuración regional: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar idioma del usuario
  static Future<Map<String, dynamic>> updateUserLanguage(String language) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/localization/user-language'),
        headers: headers,
        body: json.encode({'language': language}),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar idioma');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener idioma actual del usuario
  static Future<Map<String, dynamic>> getUserLanguage() async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/user-language'),
        headers: headers,
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener idioma del usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Formatear moneda según configuración regional
  static Future<Map<String, dynamic>> formatCurrency({
    required double amount,
    required String language,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/localization/format-currency'),
        headers: headers,
        body: json.encode({
          'amount': amount,
          'language': language,
        }),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al formatear moneda: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Formatear fecha según configuración regional
  static Future<Map<String, dynamic>> formatDate({
    required String date,
    required String language,
    String format = 'date',
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/localization/format-date'),
        headers: headers,
        body: json.encode({
          'date': date,
          'language': language,
          'format': format,
        }),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al formatear fecha: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener configuración completa de localización
  static Future<Map<String, dynamic>> getLocalizationConfig(String language) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/config?language=$language'),
        headers: headers,
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener configuración de localización: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Formatear moneda localmente
  static String formatCurrencyLocally(double amount, String language) {
    final settings = getCurrencySettings(language);
    final symbol = settings['symbol']!;
    final position = settings['position']!;
    final decimal = settings['decimal']!;
    final thousands = settings['thousands']!;
    
    final formatted = amount.toStringAsFixed(2).replaceAll('.', decimal);
    
    if (position == 'before') {
      return '$symbol$formatted';
    } else {
      return '$formatted $symbol';
    }
  }

  /// Formatear fecha localmente
  static String formatDateLocally(DateTime date, String language, String format) {
    final settings = getDateSettings(language);
    
    switch (format) {
      case 'date':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case 'time':
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      case 'datetime':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      case 'relative':
        return getRelativeDate(date);
      default:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Obtener configuración de moneda por idioma
  static Map<String, String> getCurrencySettings(String language) {
    final settings = {
      'es': {
        'symbol': '\$',
        'position': 'before',
        'decimal': '.',
        'thousands': ',',
      },
      'en': {
        'symbol': '\$',
        'position': 'before',
        'decimal': '.',
        'thousands': ',',
      },
      'pt': {
        'symbol': 'R\$',
        'position': 'before',
        'decimal': ',',
        'thousands': '.',
      },
      'fr': {
        'symbol': '€',
        'position': 'after',
        'decimal': ',',
        'thousands': ' ',
      },
    };
    
    return settings[language] ?? settings['es']!;
  }

  /// Obtener configuración de fecha por idioma
  static Map<String, String> getDateSettings(String language) {
    final settings = {
      'es': {
        'date_format': 'dd/MM/yyyy',
        'time_format': 'HH:mm',
        'datetime_format': 'dd/MM/yyyy HH:mm',
      },
      'en': {
        'date_format': 'MM/dd/yyyy',
        'time_format': 'hh:mm a',
        'datetime_format': 'MM/dd/yyyy hh:mm a',
      },
      'pt': {
        'date_format': 'dd/MM/yyyy',
        'time_format': 'HH:mm',
        'datetime_format': 'dd/MM/yyyy HH:mm',
      },
      'fr': {
        'date_format': 'dd/MM/yyyy',
        'time_format': 'HH:mm',
        'datetime_format': 'dd/MM/yyyy HH:mm',
      },
    };
    
    return settings[language] ?? settings['es']!;
  }

  /// Obtener fecha relativa
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minutos';
    } else {
      return 'ahora';
    }
  }

  /// Obtener traducción específica
  static String getTranslation(Map<String, dynamic> translations, String key, String language) {
    try {
      final keys = key.split('.');
      dynamic current = translations;
      
      for (String k in keys) {
        if (current is Map && current.containsKey(k)) {
          current = current[k];
        } else {
          return key; // Retornar la clave si no se encuentra la traducción
        }
      }
      
      if (current is String) {
        return current;
      } else {
        return key;
      }
    } catch (e) {
      return key;
    }
  }

  /// Obtener idioma por defecto
  static String getDefaultLanguage() {
    return 'es';
  }

  /// Verificar si un idioma es válido
  static bool isValidLanguage(String language) {
    final validLanguages = ['es', 'en', 'pt', 'fr'];
    return validLanguages.contains(language);
  }

  /// Obtener nombre del idioma
  static String getLanguageName(String languageCode) {
    final names = {
      'es': 'Español',
      'en': 'English',
      'pt': 'Português',
      'fr': 'Français',
    };
    
    return names[languageCode] ?? languageCode;
  }

  /// Obtener bandera del idioma
  static String getLanguageFlag(String languageCode) {
    final flags = {
      'es': '🇪🇸',
      'en': '🇺🇸',
      'pt': '🇧🇷',
      'fr': '🇫🇷',
    };
    
    return flags[languageCode] ?? '🌐';
  }

  /// Obtener zona horaria por idioma
  static String getTimezone(String language) {
    final timezones = {
      'es': 'America/Mexico_City',
      'en': 'America/New_York',
      'pt': 'America/Sao_Paulo',
      'fr': 'Europe/Paris',
    };
    
    return timezones[language] ?? 'UTC';
  }

  /// Obtener locale por idioma
  static String getLocale(String language) {
    final locales = {
      'es': 'es_MX',
      'en': 'en_US',
      'pt': 'pt_BR',
      'fr': 'fr_FR',
    };
    
    return locales[language] ?? 'en_US';
  }
} 