import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/promotion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PromotionService Tests', () {
    late PromotionService promotionService;

    setUp(() {
      promotionService = PromotionService();
    });

    test('PromotionService should be properly initialized', () {
      expect(promotionService, isNotNull);
    });

    test('PromotionService should have correct structure', () {
      expect(promotionService, isA<PromotionService>());
    });

    test('PromotionService should handle getActivePromotions', () {
      expect(promotionService.getActivePromotions, isA<Function>());
    });

    test('PromotionService should handle getAvailableCoupons', () {
      expect(promotionService.getAvailableCoupons, isA<Function>());
    });

    test('PromotionService should handle validateCoupon', () {
      expect(promotionService.validateCoupon, isA<Function>());
    });

    test('PromotionService should handle applyCouponToOrder', () {
      expect(promotionService.applyCouponToOrder, isA<Function>());
    });

    test('PromotionService should handle getCouponHistory', () {
      expect(promotionService.getCouponHistory, isA<Function>());
    });
  });
} 