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
    
    // Check if we have a specific error for this status code
    if (statusCodeErrors.containsKey(statusCode)) {
      final errorType = statusCodeErrors[statusCode]!;
      return errorMessages[errorType] ?? 'Error $statusCode';
    }
    
    // Try to parse error from response body
    if (responseBody != null && responseBody.isNotEmpty) {
      try {
        final Map<String, dynamic> errorData = json.decode(responseBody);
        if (errorData.containsKey('message')) {
          return errorData['message'];
        }
      } catch (e) {
        _logger.w('Could not parse error response: $e');
      }
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
      return error;
    }
    
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return errorMessages[networkError]!;
    }
    
    if (error.toString().contains('Unauthorized') ||
        error.toString().contains('Forbidden')) {
      return errorMessages[authenticationError]!;
    }
    
    if (error.toString().contains('FormatException') ||
        error.toString().contains('Invalid')) {
      return errorMessages[validationError]!;
    }
    
    return errorMessages[unknownError]!;
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
  
  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is String) {
      return error;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return errorMessages[networkError]!;
    }
    
    if (errorString.contains('auth') || errorString.contains('token')) {
      return errorMessages[authenticationError]!;
    }
    
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return errorMessages[validationError]!;
    }
    
    return errorMessages[unknownError]!;
  }
}

// Extension for easier error handling
extension ErrorHandlerExtension on Exception {
  String get userFriendlyMessage => ErrorHandler.getUserFriendlyMessage(this);
} 