import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class BuyerPaymentService {
  final Logger _logger = Logger();

  // GET /api/buyer/payments/methods - Obtener métodos de pago del buyer
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/methods');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener métodos de pago: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getPaymentMethods: $e');
      throw Exception('Error al obtener métodos de pago: $e');
    }
  }

  // POST /api/buyer/payments/card - Procesar pago con tarjeta
  Future<Map<String, dynamic>> processCardPayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/card');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(paymentData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al procesar pago con tarjeta');
        }
      } else {
        throw Exception('Error al procesar pago con tarjeta: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en processCardPayment: $e');
      throw Exception('Error al procesar pago con tarjeta: $e');
    }
  }

  // POST /api/buyer/payments/cash - Confirmar pago en efectivo
  Future<Map<String, dynamic>> confirmCashPayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/cash');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(paymentData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al confirmar pago en efectivo');
        }
      } else {
        throw Exception('Error al confirmar pago en efectivo: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en confirmCashPayment: $e');
      throw Exception('Error al confirmar pago en efectivo: $e');
    }
  }

  // POST /api/buyer/payments/mobile - Procesar pago móvil
  Future<Map<String, dynamic>> processMobilePayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/mobile');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(paymentData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al procesar pago móvil');
        }
      } else {
        throw Exception('Error al procesar pago móvil: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en processMobilePayment: $e');
      throw Exception('Error al procesar pago móvil: $e');
    }
  }

  // GET /api/buyer/payments/receipt/{orderId} - Obtener recibo de pago
  Future<Map<String, dynamic>> getPaymentReceipt(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/receipt/$orderId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al obtener recibo de pago');
        }
      } else {
        throw Exception('Error al obtener recibo de pago: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getPaymentReceipt: $e');
      throw Exception('Error al obtener recibo de pago: $e');
    }
  }

  // POST /api/buyer/payments/paypal - Procesar pago con PayPal
  Future<Map<String, dynamic>> processPayPalPayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/paypal');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(paymentData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al procesar pago con PayPal');
        }
      } else {
        throw Exception('Error al procesar pago con PayPal: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en processPayPalPayment: $e');
      throw Exception('Error al procesar pago con PayPal: $e');
    }
  }

  // POST /api/buyer/payments/mercadopago - Procesar pago con MercadoPago
  Future<Map<String, dynamic>> processMercadoPagoPayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/mercadopago');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(paymentData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al procesar pago con MercadoPago');
        }
      } else {
        throw Exception('Error al procesar pago con MercadoPago: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en processMercadoPagoPayment: $e');
      throw Exception('Error al procesar pago con MercadoPago: $e');
    }
  }

  // POST /api/buyer/payments/refund - Solicitar reembolso
  Future<Map<String, dynamic>> requestRefund(Map<String, dynamic> refundData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/refund');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(refundData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al solicitar reembolso');
        }
      } else {
        throw Exception('Error al solicitar reembolso: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en requestRefund: $e');
      throw Exception('Error al solicitar reembolso: $e');
    }
  }

  // GET /api/buyer/payments/history - Obtener historial de pagos
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/history');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener historial de pagos: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getPaymentHistory: $e');
      throw Exception('Error al obtener historial de pagos: $e');
    }
  }

  // GET /api/buyer/payments/statistics - Obtener estadísticas de pagos
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/payments/statistics');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
        return {};
      } else {
        throw Exception('Error al obtener estadísticas de pagos: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getPaymentStatistics: $e');
      throw Exception('Error al obtener estadísticas de pagos: $e');
    }
  }
} 