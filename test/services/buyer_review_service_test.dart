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

    test('normalizeReviewsResponseData handles paginated map', () {
      final data = {
        'reviews': [
          {'id': 1, 'rating': 5}
        ],
        'pagination': {'current_page': 1}
      };
      final normalized = normalizeReviewsResponseData(data);
      expect(normalized, hasLength(1));
      expect(normalized.first['id'], 1);
    });

    test('normalizeReviewsResponseData handles list payload', () {
      final data = [
        {'id': 2, 'rating': 4}
      ];
      final normalized = normalizeReviewsResponseData(data);
      expect(normalized, hasLength(1));
      expect(normalized.first['id'], 2);
    });

    test('extractApiMessage returns backend message when present', () {
      final message = extractApiMessage(
        '{"success":false,"message":"Ya calificaste esta orden"}',
        'fallback',
      );
      expect(message, 'Ya calificaste esta orden');
    });

    test('extractApiMessage falls back on invalid json', () {
      final message = extractApiMessage('not-json', 'fallback message');
      expect(message, 'fallback message');
    });

    test('extractApiError returns error_code and message', () {
      final apiError = extractApiError(
        '{"success":false,"message":"Duplicado","error_code":"REVIEWS_DUPLICATE_REVIEW"}',
        'fallback',
      );
      expect(apiError['error_code'], 'REVIEWS_DUPLICATE_REVIEW');
      expect(apiError['message'], 'Duplicado');
    });

    test('extractApiError falls back safely', () {
      final apiError = extractApiError('invalid-json', 'fallback');
      expect(apiError['error_code'], 'UNKNOWN');
      expect(apiError['message'], 'fallback');
    });
  });
} 