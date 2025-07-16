import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix_eats_front/features/services/commerce_product_service.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
import 'commerce_product_service_test.mocks.dart';

void main() {
  group('CommerceProductService Tests', () {
    late MockClient mockClient;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockClient = MockClient();
      mockStorage = MockFlutterSecureStorage();
    });

    group('getProducts', () {
      test('should return list of products when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "name": "Product 1",
              "description": "Description 1",
              "price": 10.99,
              "available": true,
              "image": "https://example.com/image1.jpg"
            },
            {
              "id": 2,
              "name": "Product 2",
              "description": "Description 2",
              "price": 15.99,
              "available": false,
              "image": "https://example.com/image2.jpg"
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.getProducts();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result[0]['name'], 'Product 1');
        expect(result[0]['price'], 10.99);
        expect(result[0]['available'], true);
        expect(result[1]['name'], 'Product 2');
        expect(result[1]['available'], false);
      });

      test('should return filtered products when search parameter is provided', () async {
        // Arrange
        const token = 'test_token';
        const searchQuery = 'pizza';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "name": "Pizza Margherita",
              "description": "Classic pizza",
              "price": 12.99,
              "available": true
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.getProducts(search: searchQuery);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result[0]['name'], 'Pizza Margherita');
      });

      test('should throw exception when token is not found', () async {
        // Arrange
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => CommerceProductService.getProducts(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when API call fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

        // Act & Assert
        expect(
          () => CommerceProductService.getProducts(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getProduct', () {
      test('should return product when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        const productId = 1;
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 1,
            "name": "Test Product",
            "description": "Test Description",
            "price": 9.99,
            "available": true,
            "image": "https://example.com/image.jpg"
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.getProduct(productId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 1);
        expect(result['name'], 'Test Product');
        expect(result['price'], 9.99);
        expect(result['available'], true);
      });

      test('should throw exception when product not found', () async {
        // Arrange
        const token = 'test_token';
        const productId = 999;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Product not found"}', 404));

        // Act & Assert
        expect(
          () => CommerceProductService.getProduct(productId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('createProduct', () {
      test('should create product successfully', () async {
        // Arrange
        const token = 'test_token';
        const productData = {
          'name': 'New Product',
          'description': 'New Description',
          'price': 19.99,
          'available': true,
        };
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 3,
            "name": "New Product",
            "description": "New Description",
            "price": 19.99,
            "available": true
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 201));

        // Act
        final result = await CommerceProductService.createProduct(productData);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 3);
        expect(result['name'], 'New Product');
        expect(result['price'], 19.99);
      });

      test('should throw exception when product creation fails', () async {
        // Arrange
        const token = 'test_token';
        const productData = {'name': 'Invalid Product'};
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Validation failed"}', 422));

        // Act & Assert
        expect(
          () => CommerceProductService.createProduct(productData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateProduct', () {
      test('should update product successfully', () async {
        // Arrange
        const token = 'test_token';
        const productId = 1;
        const updateData = {
          'name': 'Updated Product',
          'price': 25.99,
        };
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 1,
            "name": "Updated Product",
            "description": "Original Description",
            "price": 25.99,
            "available": true
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.updateProduct(productId, updateData);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 1);
        expect(result['name'], 'Updated Product');
        expect(result['price'], 25.99);
      });

      test('should throw exception when product update fails', () async {
        // Arrange
        const token = 'test_token';
        const productId = 1;
        const updateData = {'price': -5.0};
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Invalid price"}', 422));

        // Act & Assert
        expect(
          () => CommerceProductService.updateProduct(productId, updateData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteProduct', () {
      test('should delete product successfully', () async {
        // Arrange
        const token = 'test_token';
        const productId = 1;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act & Assert
        expect(
          () => CommerceProductService.deleteProduct(productId),
          returnsNormally,
        );
      });

      test('should throw exception when product deletion fails', () async {
        // Arrange
        const token = 'test_token';
        const productId = 999;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Product not found"}', 404));

        // Act & Assert
        expect(
          () => CommerceProductService.deleteProduct(productId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('toggleProductAvailability', () {
      test('should toggle product availability successfully', () async {
        // Arrange
        const token = 'test_token';
        const productId = 1;
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 1,
            "name": "Test Product",
            "available": false
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.toggleProductAvailability(productId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 1);
        expect(result['available'], false);
      });
    });

    group('getProductStats', () {
      test('should return product statistics successfully', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "total_products": 10,
            "available_products": 8,
            "unavailable_products": 2,
            "total_revenue": 1500.50,
            "average_price": 15.50
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.getProductStats();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['total_products'], 10);
        expect(result['available_products'], 8);
        expect(result['total_revenue'], 1500.50);
        expect(result['average_price'], 15.50);
      });
    });

    group('getAvailableProducts', () {
      test('should return only available products', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "name": "Available Product 1",
              "available": true
            },
            {
              "id": 2,
              "name": "Available Product 2",
              "available": true
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.getAvailableProducts();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result[0]['available'], true);
        expect(result[1]['available'], true);
      });
    });

    group('getUnavailableProducts', () {
      test('should return only unavailable products', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 3,
              "name": "Unavailable Product 1",
              "available": false
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await CommerceProductService.getUnavailableProducts();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result[0]['available'], false);
      });
    });
  });
} 