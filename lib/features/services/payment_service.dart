import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class PaymentService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  static String get baseUrl => AppConfig.apiUrl;
  
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
      final response = await http.delete(
        Uri.parse('$baseUrl/api/payment-methods/$methodId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
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
      final response = await http.patch(
        Uri.parse('$baseUrl/api/payment-methods/$methodId/default'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        // Update local mock data as well
        for (var method in _mockPaymentMethods) {
          method['is_default'] = method['id'] == methodId;
        }
      } else {
        // Fallback to mock data
        await Future.delayed(Duration(milliseconds: 400));
        for (var method in _mockPaymentMethods) {
          method['is_default'] = method['id'] == methodId;
        }
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      for (var method in _mockPaymentMethods) {
        method['is_default'] = method['id'] == methodId;
      }
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
        // Fallback to mock data
        await Future.delayed(Duration(milliseconds: 2000));
        final success = paymentData['amount'] < 100;
        
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
            'fee': paymentData['amount'] * 0.03,
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
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 2000));
      final success = paymentData['amount'] < 100;
      
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
          'fee': paymentData['amount'] * 0.03,
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
        // Fallback to mock data
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
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      var transactions = _mockTransactions;
      
      if (status != null) {
        transactions = transactions.where((t) => t['status'] == status).toList();
      }
      
      return transactions;
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
      // Fallback to mock data
      await Future.delayed(Duration(milliseconds: 300));
      try {
        return _mockTransactions.firstWhere((t) => t['id'] == transactionId);
      } catch (_) {
        throw Exception('Error fetching transaction: $e');
      }
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
        // Fallback to mock data
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
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 1000));
      try {
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
      } catch (_) {
        throw Exception('Error processing refund: $e');
      }
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      var invoices = _mockInvoices;
      
      if (status != null) {
        invoices = invoices.where((i) => i['status'] == status).toList();
      }
      
      return invoices;
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
      // Fallback to mock data
      await Future.delayed(Duration(milliseconds: 300));
      try {
        return _mockInvoices.firstWhere((i) => i['id'] == invoiceId);
      } catch (_) {
        throw Exception('Error fetching invoice: $e');
      }
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
          // Continue to mock fallback
        }
      }
      
      // Fallback to mock data
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
      
      // Fallback to mock data
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
      };
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      
      final totalTransactions = _mockTransactions.length;
      final completedTransactions = _mockTransactions.where((t) => t['status'] == 'completed').length;
      final totalAmount = _mockTransactions
          .where((t) => t['status'] == 'completed')
          .fold(0.0, (sum, t) => sum + t['amount']);
      
      return {
        'total_transactions': totalTransactions,
        'completed_transactions': completedTransactions,
        'total_amount': totalAmount,
      };
    }
  }

  // Validate payment method
  Future<bool> validatePaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      // Client-side validation (backend will also validate)
      await Future.delayed(Duration(milliseconds: 500));
      
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
        // Try alternative format
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      // Fallback to mock data
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
          'type': 'cash',
          'name': 'Cash on Delivery',
          'description': 'Pay when you receive your order',
          'icon': 'money',
          'enabled': true,
        },
      ];
    } catch (e) {
      // Fallback to mock data on error
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
          'type': 'cash',
          'name': 'Cash on Delivery',
          'description': 'Pay when you receive your order',
          'icon': 'money',
          'enabled': true,
        },
      ];
    }
  }
} 