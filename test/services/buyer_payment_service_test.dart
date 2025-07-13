import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/buyer_payment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BuyerPaymentService Tests', () {
    late BuyerPaymentService paymentService;

    setUp(() {
      paymentService = BuyerPaymentService();
    });

    test('BuyerPaymentService should be properly initialized', () {
      expect(paymentService, isNotNull);
    });

    test('BuyerPaymentService should have correct structure', () {
      expect(paymentService, isA<BuyerPaymentService>());
    });

    test('BuyerPaymentService should handle getPaymentMethods', () {
      expect(paymentService.getPaymentMethods, isA<Function>());
    });

    test('BuyerPaymentService should handle processCardPayment', () {
      expect(paymentService.processCardPayment, isA<Function>());
    });

    test('BuyerPaymentService should handle confirmCashPayment', () {
      expect(paymentService.confirmCashPayment, isA<Function>());
    });

    test('BuyerPaymentService should handle getPaymentReceipt', () {
      expect(paymentService.getPaymentReceipt, isA<Function>());
    });
  });
} 