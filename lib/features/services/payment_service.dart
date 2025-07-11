import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockPaymentMethods = [
    {
      'id': 1,
      'type': 'card',
      'brand': 'Visa',
      'last4': '1234',
      'exp_month': 12,
      'exp_year': 2025,
      'is_default': true,
      'cardholder_name': 'Juan Pérez',
    },
    {
      'id': 2,
      'type': 'card',
      'brand': 'Mastercard',
      'last4': '5678',
      'exp_month': 8,
      'exp_year': 2026,
      'is_default': false,
      'cardholder_name': 'Juan Pérez',
    },
    {
      'id': 3,
      'type': 'digital_wallet',
      'brand': 'PayPal',
      'email': 'juan.perez@email.com',
      'is_default': false,
    },
  ];

  static final List<Map<String, dynamic>> _mockTransactions = [
    {
      'id': 1,
      'order_id': 123,
      'amount': 45.50,
      'currency': 'USD',
      'status': 'completed',
      'payment_method': 'Visa ****1234',
      'created_at': '2024-01-15T10:30:00',
      'transaction_id': 'txn_123456789',
      'fee': 1.50,
      'description': 'Orden #ORD-123 - Restaurante El Buen Sabor',
    },
    {
      'id': 2,
      'order_id': 124,
      'amount': 32.00,
      'currency': 'USD',
      'status': 'pending',
      'payment_method': 'Mastercard ****5678',
      'created_at': '2024-01-15T11:15:00',
      'transaction_id': 'txn_987654321',
      'fee': 1.20,
      'description': 'Orden #ORD-124 - Pizzería La Italiana',
    },
    {
      'id': 3,
      'order_id': 125,
      'amount': 28.75,
      'currency': 'USD',
      'status': 'failed',
      'payment_method': 'PayPal',
      'created_at': '2024-01-15T09:45:00',
      'transaction_id': 'txn_456789123',
      'fee': 0.00,
      'description': 'Orden #ORD-125 - Café Central',
      'failure_reason': 'Insufficient funds',
    },
  ];

  static final List<Map<String, dynamic>> _mockInvoices = [
    {
      'id': 1,
      'invoice_number': 'INV-001',
      'order_id': 123,
      'amount': 45.50,
      'tax': 3.50,
      'delivery_fee': 2.00,
      'total': 51.00,
      'currency': 'USD',
      'status': 'paid',
      'created_at': '2024-01-15T10:30:00',
      'paid_at': '2024-01-15T10:32:00',
      'items': [
        {
          'name': 'Hamburguesa Clásica',
          'quantity': 2,
          'unit_price': 15.00,
          'total': 30.00,
        },
        {
          'name': 'Coca Cola',
          'quantity': 1,
          'unit_price': 3.50,
          'total': 3.50,
        },
        {
          'name': 'Papas Fritas',
          'quantity': 1,
          'unit_price': 4.00,
          'total': 4.00,
        },
      ],
    },
  ];

  // Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/methods'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 400));
        return _mockPaymentMethods;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      return _mockPaymentMethods;
    }
  }

  // Add payment method
  Future<Map<String, dynamic>> addPaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/api/payment/methods'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMethod = data['data'] ?? {
          'id': _mockPaymentMethods.length + 1,
          ...paymentData,
          'is_default': _mockPaymentMethods.isEmpty,
        };
        _mockPaymentMethods.add(newMethod);
        return newMethod;
      } else {
        // Fallback to mock data
        await Future.delayed(Duration(milliseconds: 600));
        final newMethod = {
          'id': _mockPaymentMethods.length + 1,
          ...paymentData,
          'is_default': _mockPaymentMethods.isEmpty,
        };
        _mockPaymentMethods.add(newMethod);
        return newMethod;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      final newMethod = {
        'id': _mockPaymentMethods.length + 1,
        ...paymentData,
        'is_default': _mockPaymentMethods.isEmpty,
      };
      _mockPaymentMethods.add(newMethod);
      return newMethod;
    }
  }

  // Update payment method
  Future<Map<String, dynamic>> updatePaymentMethod(int methodId, Map<String, dynamic> updates) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/api/payment/methods/$methodId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedMethod = data['data'] ?? {};
        final index = _mockPaymentMethods.indexWhere((m) => m['id'] == methodId);
        if (index != -1) {
          _mockPaymentMethods[index] = {..._mockPaymentMethods[index], ...updatedMethod};
          return _mockPaymentMethods[index];
        }
        return updatedMethod;
      } else {
        // Fallback to mock data
        await Future.delayed(Duration(milliseconds: 500));
        final index = _mockPaymentMethods.indexWhere((m) => m['id'] == methodId);
        if (index != -1) {
          _mockPaymentMethods[index] = {..._mockPaymentMethods[index], ...updates};
          return _mockPaymentMethods[index];
        }
        throw Exception('Payment method not found');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockPaymentMethods.indexWhere((m) => m['id'] == methodId);
      if (index != -1) {
        _mockPaymentMethods[index] = {..._mockPaymentMethods[index], ...updates};
        return _mockPaymentMethods[index];
      }
      throw Exception('Payment method not found');
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(int methodId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/payment/methods/$methodId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local mock data as well
        _mockPaymentMethods.removeWhere((m) => m['id'] == methodId);
      } else {
        // Fallback to mock data
        await Future.delayed(Duration(milliseconds: 400));
        _mockPaymentMethods.removeWhere((m) => m['id'] == methodId);
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      _mockPaymentMethods.removeWhere((m) => m['id'] == methodId);
    }
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(int methodId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.put('/payment/methods/$methodId/default');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      for (var method in _mockPaymentMethods) {
        method['is_default'] = method['id'] == methodId;
      }
    } catch (e) {
      throw Exception('Error setting default payment method: $e');
    }
  }

  // Process payment
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> paymentData) async {
    try {
      // TODO: Replace with real payment processing
      // final response = await _apiService.post('/payment/process', paymentData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 2000));
      
      // Simulate payment processing
      final success = paymentData['amount'] < 100; // Mock success condition
      
      if (success) {
        final transaction = {
          'id': _mockTransactions.length + 1,
          'order_id': paymentData['order_id'],
          'amount': paymentData['amount'],
          'currency': paymentData['currency'] ?? 'USD',
          'status': 'completed',
          'payment_method': paymentData['payment_method'],
          'created_at': DateTime.now().toIso8601String(),
          'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          'fee': paymentData['amount'] * 0.03, // 3% fee
          'description': paymentData['description'],
        };
        
        _mockTransactions.add(transaction);
        
        return {
          'success': true,
          'transaction': transaction,
          'message': 'Payment processed successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment failed',
          'message': 'Insufficient funds or card declined',
        };
      }
    } catch (e) {
      throw Exception('Error processing payment: $e');
    }
  }

  // Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/payment/transactions', {
      //   'status': status,
      //   'start_date': startDate?.toIso8601String(),
      //   'end_date': endDate?.toIso8601String(),
      // });
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      var transactions = _mockTransactions;
      
      if (status != null) {
        transactions = transactions.where((t) => t['status'] == status).toList();
      }
      
      if (startDate != null) {
        transactions = transactions.where((t) {
          final transactionDate = DateTime.parse(t['created_at']);
          return transactionDate.isAfter(startDate);
        }).toList();
      }
      
      if (endDate != null) {
        transactions = transactions.where((t) {
          final transactionDate = DateTime.parse(t['created_at']);
          return transactionDate.isBefore(endDate);
        }).toList();
      }
      
      return transactions;
    } catch (e) {
      throw Exception('Error fetching transaction history: $e');
    }
  }

  // Get transaction by ID
  Future<Map<String, dynamic>> getTransactionById(int transactionId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/payment/transactions/$transactionId');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final transaction = _mockTransactions.firstWhere((t) => t['id'] == transactionId);
      return transaction;
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }

  // Refund payment
  Future<Map<String, dynamic>> refundPayment(int transactionId, {double? amount}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/payment/refund', {
      //   'transaction_id': transactionId,
      //   'amount': amount,
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 1000));
      
      final transaction = _mockTransactions.firstWhere((t) => t['id'] == transactionId);
      final refundAmount = amount ?? transaction['amount'];
      
      final refund = {
        'id': _mockTransactions.length + 1,
        'original_transaction_id': transactionId,
        'amount': refundAmount,
        'currency': transaction['currency'],
        'status': 'completed',
        'type': 'refund',
        'created_at': DateTime.now().toIso8601String(),
        'transaction_id': 'ref_${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Refund for ${transaction['description']}',
      };
      
      _mockTransactions.add(refund);
      
      return {
        'success': true,
        'refund': refund,
        'message': 'Refund processed successfully',
      };
    } catch (e) {
      throw Exception('Error processing refund: $e');
    }
  }

  // Get invoices
  Future<List<Map<String, dynamic>>> getInvoices({String? status}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/payment/invoices', {'status': status});
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      var invoices = _mockInvoices;
      
      if (status != null) {
        invoices = invoices.where((i) => i['status'] == status).toList();
      }
      
      return invoices;
    } catch (e) {
      throw Exception('Error fetching invoices: $e');
    }
  }

  // Get invoice by ID
  Future<Map<String, dynamic>> getInvoiceById(int invoiceId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/payment/invoices/$invoiceId');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final invoice = _mockInvoices.firstWhere((i) => i['id'] == invoiceId);
      return invoice;
    } catch (e) {
      throw Exception('Error fetching invoice: $e');
    }
  }

  // Generate invoice
  Future<Map<String, dynamic>> generateInvoice(Map<String, dynamic> invoiceData) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/payment/invoices', invoiceData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 800));
      
      final invoice = {
        'id': _mockInvoices.length + 1,
        'invoice_number': 'INV-${(_mockInvoices.length + 1).toString().padLeft(3, '0')}',
        ...invoiceData,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      };
      
      _mockInvoices.add(invoice);
      return invoice;
    } catch (e) {
      throw Exception('Error generating invoice: $e');
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/payment/statistics');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      
      final totalTransactions = _mockTransactions.length;
      final completedTransactions = _mockTransactions.where((t) => t['status'] == 'completed').length;
      final totalAmount = _mockTransactions
          .where((t) => t['status'] == 'completed')
          .fold(0.0, (sum, t) => sum + t['amount']);
      final totalFees = _mockTransactions
          .where((t) => t['status'] == 'completed')
          .fold(0.0, (sum, t) => sum + (t['fee'] ?? 0.0));
      
      return {
        'total_transactions': totalTransactions,
        'completed_transactions': completedTransactions,
        'failed_transactions': _mockTransactions.where((t) => t['status'] == 'failed').length,
        'pending_transactions': _mockTransactions.where((t) => t['status'] == 'pending').length,
        'total_amount': totalAmount,
        'total_fees': totalFees,
        'success_rate': totalTransactions > 0 ? (completedTransactions / totalTransactions * 100) : 0,
        'average_transaction': totalTransactions > 0 ? totalAmount / completedTransactions : 0,
        'monthly_stats': [
          {'month': 'Enero', 'transactions': 45, 'amount': 1250.50},
          {'month': 'Febrero', 'transactions': 52, 'amount': 1380.75},
          {'month': 'Marzo', 'transactions': 48, 'amount': 1290.25},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching payment statistics: $e');
    }
  }

  // Validate payment method
  Future<bool> validatePaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      // TODO: Replace with real validation
      // final response = await _apiService.post('/payment/validate', paymentData);
      // return response['data']['valid'];
      
      // Mock validation for now
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Simple validation rules
      if (paymentData['type'] == 'card') {
        final cardNumber = paymentData['card_number'] ?? '';
        final expMonth = paymentData['exp_month'];
        final expYear = paymentData['exp_year'];
        final cvv = paymentData['cvv'] ?? '';
        
        return cardNumber.length >= 13 &&
               cardNumber.length <= 19 &&
               expMonth >= 1 &&
               expMonth <= 12 &&
               expYear >= DateTime.now().year &&
               cvv.length >= 3 &&
               cvv.length <= 4;
      }
      
      return true;
    } catch (e) {
      throw Exception('Error validating payment method: $e');
    }
  }

  // Get supported payment methods
  Future<List<Map<String, dynamic>>> getSupportedPaymentMethods() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/payment/supported-methods');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return [
        {
          'type': 'card',
          'name': 'Credit/Debit Card',
          'description': 'Pay with Visa, Mastercard, American Express',
          'icon': 'credit_card',
          'enabled': true,
        },
        {
          'type': 'digital_wallet',
          'name': 'Digital Wallets',
          'description': 'Pay with PayPal, Apple Pay, Google Pay',
          'icon': 'account_balance_wallet',
          'enabled': true,
        },
        {
          'type': 'bank_transfer',
          'name': 'Bank Transfer',
          'description': 'Direct bank transfer',
          'icon': 'account_balance',
          'enabled': false,
        },
        {
          'type': 'cash',
          'name': 'Cash on Delivery',
          'description': 'Pay when you receive your order',
          'icon': 'money',
          'enabled': true,
        },
      ];
    } catch (e) {
      throw Exception('Error fetching supported payment methods: $e');
    }
  }
} 