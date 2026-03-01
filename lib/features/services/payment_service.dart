import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class PaymentService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  // Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment-methods'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        // Try alternative format
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener métodos de pago: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add payment method
  Future<Map<String, dynamic>> addPaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payment-methods'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        // Try alternative format
        if (data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        throw Exception('Error adding payment method: Invalid response');
      } else {
        throw Exception('Error al agregar método de pago: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update payment method
  Future<Map<String, dynamic>> updatePaymentMethod(int methodId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/payment-methods/$methodId'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        // Try alternative format
        if (data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        throw Exception('Error updating payment method: Invalid response');
      } else {
        throw Exception('Error al actualizar método de pago: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(int methodId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/payment-methods/$methodId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        throw Exception('Error al eliminar método de pago: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(int methodId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/payment-methods/$methodId/default'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Error al establecer método predeterminado: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Process payment
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/process'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'transaction': data['data'],
            'message': data['message'] ?? 'Payment processed successfully',
          };
        }
        throw Exception('Error processing payment: Invalid response');
      } else {
        throw Exception('Error al procesar pago: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/payments/history').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener historial de transacciones: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get transaction by ID
  Future<Map<String, dynamic>> getTransactionById(int transactionId) async {
    try {
      // Try to get from history first, then filter by ID
      final history = await getTransactionHistory();
      final transaction = history.firstWhere(
        (t) => t['id'] == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      return transaction;
    } catch (e) {
      rethrow;
    }
  }

  // Refund payment
  Future<Map<String, dynamic>> refundPayment(int transactionId, {double? amount}) async {
    try {
      final refundData = <String, dynamic>{};
      if (amount != null) refundData['amount'] = amount;

      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/$transactionId/refund'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(refundData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'refund': data['data'],
            'message': data['message'] ?? 'Refund processed successfully',
          };
        }
        throw Exception('Error processing refund: Invalid response');
      } else {
        throw Exception('Error al procesar reembolso: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get invoices
  Future<List<Map<String, dynamic>>> getInvoices({String? status}) async {
    try {
      // Use payment history as invoices (orders with payment info)
      final history = await getTransactionHistory();
      
      // Convert transactions to invoice-like format
      final invoices = history.map((transaction) {
        return {
          'id': transaction['id'],
          'invoice_number': 'INV-${transaction['id'].toString().padLeft(3, '0')}',
          'order_id': transaction['order_id'],
          'amount': transaction['amount'],
          'total': transaction['amount'] + (transaction['fee'] ?? 0.0),
          'currency': transaction['currency'] ?? 'USD',
          'status': transaction['status'],
          'created_at': transaction['created_at'],
          'paid_at': transaction['status'] == 'completed' ? transaction['created_at'] : null,
        };
      }).toList();
      
      if (status != null) {
        return invoices.where((i) => i['status'] == status).toList();
      }
      
        return invoices;
    } catch (e) {
      rethrow;
    }
  }

  // Get invoice by ID
  Future<Map<String, dynamic>> getInvoiceById(int invoiceId) async {
    try {
      // Try to get from invoices list
      final invoices = await getInvoices();
      final invoice = invoices.firstWhere(
        (i) => i['id'] == invoiceId,
        orElse: () => throw Exception('Invoice not found'),
      );
      return invoice;
    } catch (e) {
      rethrow;
    }
  }

  // Generate invoice
  Future<Map<String, dynamic>> generateInvoice(Map<String, dynamic> invoiceData) async {
    try {
      // Invoices are typically generated from orders, so we'll use the order receipt endpoint
      // or create from transaction data
      if (invoiceData.containsKey('order_id')) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/api/buyer/payments/receipt/${invoiceData['order_id']}'),
            headers: await AuthHelper.getAuthHeaders(),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              return data['data'];
            }
          }
        } catch (_) {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Error generating invoice: No receipt available for order');
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/statistics'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      
      throw Exception('Error al obtener estadísticas de pago: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  // Validate payment method
  Future<bool> validatePaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      // Client-side validation (backend will also validate)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simple validation rules
      if (paymentData['type'] == 'card') {
        final cardNumber = paymentData['card_number'] ?? '';
        final expMonth = paymentData['exp_month'];
        final expYear = paymentData['exp_year'];
        final cvv = paymentData['cvv'] ?? '';
        
        final isValid = cardNumber.length >= 13 &&
               cardNumber.length <= 19 &&
               expMonth != null &&
               expMonth >= 1 &&
               expMonth <= 12 &&
               expYear != null &&
               expYear >= DateTime.now().year &&
               cvv.length >= 3 &&
               cvv.length <= 4;
        
        return isValid;
      }
      
      // For other payment types, basic validation
      if (paymentData['type'] == 'digital_wallet') {
        return paymentData['email'] != null && paymentData['email'].toString().contains('@');
      }
      
      return true;
    } catch (e) {
      throw Exception('Error validating payment method: $e');
    }
  }

  // Get supported payment methods
  Future<List<Map<String, dynamic>>> getSupportedPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/available-payment-methods'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('Error: No payment methods in response');
      }
      throw Exception('Error al obtener métodos de pago: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
} 