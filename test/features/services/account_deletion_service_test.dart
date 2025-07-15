import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix_eats_front/lib/features/services/account_deletion_service.dart';
import 'package:zonix_eats_front/lib/helpers/auth_helper.dart';

import 'account_deletion_service_test.mocks.dart';

@Skip('Fuera del MVP commerce')
@GenerateMocks([http.Client, AuthHelper])
void main() {
  group('AccountDeletionService', () {
    late MockClient mockClient;
    late MockAuthHelper mockAuthHelper;

    setUp(() {
      mockClient = MockClient();
      mockAuthHelper = MockAuthHelper();
    });

    group('requestAccountDeletion', () {
      test('should return deletion request result when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"deletion_id": "123", "status": "pending"}',
          200,
        ));

        // Act
        final result = await AccountDeletionService.requestAccountDeletion(
          reason: 'No longer using the app',
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['deletion_id'], '123');
        expect(result['status'], 'pending');
      });

      test('should include all parameters in request body', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{}', 200));

        // Act
        await AccountDeletionService.requestAccountDeletion(
          reason: 'Test reason',
          feedback: 'Test feedback',
          immediate: true,
        );

        // Assert
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: argThat(
            predicate((String body) => 
              body.contains('"reason":"Test reason"') &&
              body.contains('"feedback":"Test feedback"') &&
              body.contains('"immediate":true')
            ),
          ),
        )).called(1);
      });

      test('should throw exception when API call fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        // Act & Assert
        expect(
          () => AccountDeletionService.requestAccountDeletion(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('confirmAccountDeletion', () {
      test('should return confirmation result when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"status": "deleted", "message": "Account deleted successfully"}',
          200,
        ));

        // Act
        final result = await AccountDeletionService.confirmAccountDeletion(
          confirmationCode: '123456',
          password: 'password123',
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['status'], 'deleted');
        expect(result['message'], 'Account deleted successfully');
      });

      test('should include confirmation code and password in request body', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{}', 200));

        // Act
        await AccountDeletionService.confirmAccountDeletion(
          confirmationCode: '123456',
          password: 'password123',
        );

        // Assert
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: argThat(
            predicate((String body) => 
              body.contains('"confirmation_code":"123456"') &&
              body.contains('"password":"password123"')
            ),
          ),
        )).called(1);
      });
    });

    group('cancelDeletionRequest', () {
      test('should return cancellation result when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"status": "cancelled", "message": "Deletion request cancelled"}',
          200,
        ));

        // Act
        final result = await AccountDeletionService.cancelDeletionRequest();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['status'], 'cancelled');
        expect(result['message'], 'Deletion request cancelled');
      });
    });

    group('getDeletionStatus', () {
      test('should return deletion status when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"has_pending_request": true, "status": "pending", "scheduled_for": "2024-12-31"}',
          200,
        ));

        // Act
        final result = await AccountDeletionService.getDeletionStatus();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['has_pending_request'], true);
        expect(result['status'], 'pending');
        expect(result['scheduled_for'], '2024-12-31');
      });

      test('should throw exception when token is null', () async {
        // Arrange
        when(mockAuthHelper.getToken()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => AccountDeletionService.getDeletionStatus(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
} 