import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix_eats_front/features/services/commerce_data_service.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
import 'commerce_data_service_test.mocks.dart';

void main() {
  group('CommerceDataService Tests', () {
    late MockClient mockClient;
    late MockFlutterSecureStorage mockStorage;
    late CommerceDataService service;

    setUp(() {
      mockClient = MockClient();
      mockStorage = MockFlutterSecureStorage();
      service = CommerceDataService();
    });

    group('getCommerceProfile', () {
      test('should return commerce profile when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 1,
            "name": "Test Commerce",
            "description": "Test Description",
            "address": "Test Address",
            "phone": "123456789",
            "email": "test@commerce.com",
            "is_open": true,
            "delivery_fee": 5.0,
            "minimum_order": 10.0
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getCommerceProfile();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 1);
        expect(result['name'], 'Test Commerce');
        expect(result['is_open'], true);
        expect(result['delivery_fee'], 5.0);
      });

      test('should throw exception when token is not found', () async {
        // Arrange
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getCommerceProfile(),
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
        )).thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

        // Act & Assert
        expect(
          () => service.getCommerceProfile(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateCommerceProfile', () {
      test('should update commerce profile successfully', () async {
        // Arrange
        const token = 'test_token';
        const updateData = {
          'name': 'Updated Commerce',
          'description': 'Updated Description',
        };
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 1,
            "name": "Updated Commerce",
            "description": "Updated Description"
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
        final result = await service.updateCommerceProfile(updateData);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['name'], 'Updated Commerce');
        expect(result['description'], 'Updated Description');
      });

      test('should throw exception when update fails', () async {
        // Arrange
        const token = 'test_token';
        const updateData = {'name': 'Updated Commerce'};
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Validation failed"}', 422));

        // Act & Assert
        expect(
          () => service.updateCommerceProfile(updateData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('uploadCommerceImage', () {
      test('should upload image successfully', () async {
        // Arrange
        const token = 'test_token';
        const imagePath = '/test/path/image.jpg';
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "image_url": "https://example.com/image.jpg"
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.uploadCommerceImage(imagePath);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['image_url'], 'https://example.com/image.jpg');
      });

      test('should throw exception when image upload fails', () async {
        // Arrange
        const token = 'test_token';
        const imagePath = '/test/path/image.jpg';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Upload failed"}', 500));

        // Act & Assert
        expect(
          () => service.uploadCommerceImage(imagePath),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updatePaymentInfo', () {
      test('should update payment info successfully', () async {
        // Arrange
        const token = 'test_token';
        const paymentData = {
          'mobile_payment_enabled': true,
          'mobile_payment_number': '123456789',
        };
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "mobile_payment_enabled": true,
            "mobile_payment_number": "123456789"
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
        final result = await service.updatePaymentInfo(paymentData);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['mobile_payment_enabled'], true);
        expect(result['mobile_payment_number'], '123456789');
      });
    });

    group('updateSchedule', () {
      test('should update schedule successfully', () async {
        // Arrange
        const token = 'test_token';
        const scheduleData = {
          'monday_open': '09:00',
          'monday_close': '22:00',
          'tuesday_open': '09:00',
          'tuesday_close': '22:00',
        };
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "monday_open": "09:00",
            "monday_close": "22:00",
            "tuesday_open": "09:00",
            "tuesday_close": "22:00"
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
        final result = await service.updateSchedule(scheduleData);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['monday_open'], '09:00');
        expect(result['monday_close'], '22:00');
      });
    });

    group('updateOpenStatus', () {
      test('should update open status successfully', () async {
        // Arrange
        const token = 'test_token';
        const isOpen = true;
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "is_open": true
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
        final result = await service.updateOpenStatus(isOpen);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['is_open'], true);
      });
    });
  });
} 