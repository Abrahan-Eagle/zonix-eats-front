import 'package:logger/logger.dart';
import 'dart:convert'; // Added for json.decode

class ErrorHandler {
  static final Logger _logger = Logger();
  
  // Error types
  static const String networkError = 'NETWORK_ERROR';
  static const String authenticationError = 'AUTHENTICATION_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';
  
  // Error messages in Spanish
  static const Map<String, String> errorMessages = {
    networkError: 'Error de conexión. Verifica tu conexión a internet.',
    authenticationError: 'Sesión expirada. Por favor inicia sesión nuevamente.',
    validationError: 'Datos inválidos. Verifica la información ingresada.',
    serverError: 'Error del servidor. Intenta nuevamente en unos momentos.',
    unknownError: 'Error inesperado. Contacta soporte si persiste.',
  };
  
  // HTTP status code mappings
  static const Map<int, String> statusCodeErrors = {
    400: validationError,
    401: authenticationError,
    403: authenticationError,
    404: 'Recurso no encontrado.',
    408: networkError,
    429: 'Demasiadas solicitudes. Intenta más tarde.',
    500: serverError,
    502: serverError,
    503: serverError,
    504: networkError,
  };
  
  /// Handle HTTP response and return appropriate error message
  static String handleHttpResponse(int statusCode, String? responseBody) {
    _logger.e('HTTP Error: $statusCode - $responseBody');

    // Prioridad: mensaje del API (Laravel suele enviar `message` en JSON)
    if (responseBody != null && responseBody.isNotEmpty) {
      try {
        final Map<String, dynamic> errorData = json.decode(responseBody);
        final msg = errorData['message'];
        if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }
      } catch (e) {
        _logger.w('Could not parse error response: $e');
      }
    }

    // Códigos con plantilla fija (solo si no hubo `message` en JSON)
    if (statusCodeErrors.containsKey(statusCode)) {
      final errorType = statusCodeErrors[statusCode]!;
      return errorMessages[errorType] ?? 'Error $statusCode';
    }
    
    // Default error message
    if (statusCode >= 500) {
      return errorMessages[serverError]!;
    } else if (statusCode >= 400) {
      return errorMessages[validationError]!;
    } else {
      return errorMessages[unknownError]!;
    }
  }
  
  /// Handle general exceptions
  static String handleException(dynamic error, [StackTrace? stackTrace]) {
    _logger.e('Exception occurred', error: error, stackTrace: stackTrace);
    
    if (error is String) {
      if (_isNetworkString(error)) return errorMessages[networkError]!;
      return error;
    }
    
    final s = error.toString();
    if (_isNetworkString(s)) return errorMessages[networkError]!;
    
    if (s.contains('Unauthorized') || s.contains('Forbidden')) {
      return errorMessages[authenticationError]!;
    }
    
    if (s.contains('FormatException') || s.contains('Invalid')) {
      return errorMessages[validationError]!;
    }
    
    return errorMessages[unknownError]!;
  }

  static bool _isNetworkString(String s) {
    final lower = s.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('networkexception') ||
        lower.contains('clientexception') ||
        lower.contains('connection timed out') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('failed host lookup') ||
        lower.contains('timeoutexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('errno = 110') ||
        lower.contains('errno = 111') ||
        lower.contains('no address associated') ||
        (lower.contains('timeout') && lower.contains('future not completed'));
  }
  
  /// Log error for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    _logger.e('Error in $context', error: error, stackTrace: stackTrace);
  }
  
  /// Log warning
  static void logWarning(String context, String message) {
    _logger.w('Warning in $context: $message');
  }
  
  /// Log info
  static void logInfo(String context, String message) {
    _logger.i('Info in $context: $message');
  }
  
  /// Get user-friendly error message (never returns raw technical text).
  static String getUserFriendlyMessage(dynamic error) {
    if (error is String) {
      if (_isNetworkString(error)) return errorMessages[networkError]!;
      final lower = error.toLowerCase();
      if (lower.contains('auth') || lower.contains('token') || lower.contains('sesión')) return errorMessages[authenticationError]!;
      if (lower.contains('exception:') || lower.contains('errno') || lower.contains('stacktrace')) return errorMessages[unknownError]!;
      return error;
    }

    final s = error.toString();
    if (_isNetworkString(s)) return errorMessages[networkError]!;

    final lower = s.toLowerCase();
    if (lower.contains('auth') || lower.contains('token')) return errorMessages[authenticationError]!;
    if (lower.contains('validation') || lower.contains('invalid')) return errorMessages[validationError]!;

    return errorMessages[unknownError]!;
  }
}

// Extension for easier error handling
extension ErrorHandlerExtension on Exception {
  String get userFriendlyMessage => ErrorHandler.getUserFriendlyMessage(this);
} 