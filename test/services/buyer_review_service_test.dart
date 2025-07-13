import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/buyer_review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BuyerReviewService Tests', () {
    late BuyerReviewService reviewService;

    setUp(() {
      reviewService = BuyerReviewService();
    });

    test('BuyerReviewService should be properly initialized', () {
      expect(reviewService, isNotNull);
    });

    test('BuyerReviewService should have correct structure', () {
      expect(reviewService, isA<BuyerReviewService>());
    });

    test('BuyerReviewService should handle rateRestaurant', () {
      expect(reviewService.rateRestaurant, isA<Function>());
    });

    test('BuyerReviewService should handle rateDeliveryAgent', () {
      expect(reviewService.rateDeliveryAgent, isA<Function>());
    });

    test('BuyerReviewService should handle getRestaurantReviews', () {
      expect(reviewService.getRestaurantReviews, isA<Function>());
    });

    test('BuyerReviewService should handle getDeliveryAgentReviews', () {
      expect(reviewService.getDeliveryAgentReviews, isA<Function>());
    });
  });
} 