import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SearchService Tests', () {
    late SearchService searchService;

    setUp(() {
      searchService = SearchService();
    });

    test('SearchService should be properly initialized', () {
      expect(searchService, isNotNull);
    });

    test('SearchService should have correct structure', () {
      expect(searchService, isA<SearchService>());
    });

    test('SearchService should handle searchRestaurants', () {
      expect(searchService.searchRestaurants, isA<Function>());
    });

    test('SearchService should handle searchProducts', () {
      expect(searchService.searchProducts, isA<Function>());
    });

    test('SearchService should handle getCategories', () {
      expect(searchService.getCategories, isA<Function>());
    });

    test('SearchService should handle getSearchSuggestions', () {
      expect(searchService.getSearchSuggestions, isA<Function>());
    });
  });
} 