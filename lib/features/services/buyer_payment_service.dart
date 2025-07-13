import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class BuyerPaymentService {
  final Logger _logger = Logger();
  final _storage = const FlutterSecureStorage();

  // GET /api/buyer/payments/methods - Obtener métodos de pago del buyer
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/payments/methods');
      
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
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/payments/card');
      
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
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/payments/cash');
      
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

  // GET /api/buyer/payments/receipt/{orderId} - Obtener recibo de pago
  Future<Map<String, dynamic>> getPaymentReceipt(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/payments/receipt/$orderId');
      
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
} 