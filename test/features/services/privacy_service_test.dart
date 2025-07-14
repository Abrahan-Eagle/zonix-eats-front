import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix_eats_front/lib/features/services/privacy_service.dart';
import 'package:zonix_eats_front/lib/helpers/auth_helper.dart';

import 'privacy_service_test.mocks.dart';

@GenerateMocks([http.Client, AuthHelper])
void main() {
  group('PrivacyService', () {
    late MockClient mockClient;
    late MockAuthHelper mockAuthHelper;

    setUp(() {
      mockClient = MockClient();
      mockAuthHelper = MockAuthHelper();
    });

    group('getPrivacySettings', () {
      test('should return privacy settings when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"profile_visibility": true, "marketing_emails": false}',
          200,
        ));

        // Act
        final result = await PrivacyService.getPrivacySettings();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['profile_visibility'], true);
        expect(result['marketing_emails'], false);
      });

      test('should throw exception when token is null', () async {
        // Arrange
        when(mockAuthHelper.getToken()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => PrivacyService.getPrivacySettings(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updatePrivacySettings', () {
      test('should return updated settings when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"profile_visibility": false, "marketing_emails": true}',
          200,
        ));

        // Act
        final result = await PrivacyService.updatePrivacySettings(
          profileVisibility: false,
          marketingEmails: true,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['profile_visibility'], false);
        expect(result['marketing_emails'], true);
      });

      test('should include only provided settings in request body', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{}', 200));

        // Act
        await PrivacyService.updatePrivacySettings(
          profileVisibility: true,
          pushNotifications: false,
        );

        // Assert
        verify(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: argThat(
            predicate((String body) => 
              body.contains('"profile_visibility":true') &&
              body.contains('"push_notifications":false') &&
              !body.contains('marketing_emails') &&
              !body.contains('location_sharing')
            ),
          ),
        )).called(1);
      });
    });

    group('getPrivacyPolicy', () {
      test('should return privacy policy when API call is successful', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"content": "Privacy policy content", "version": "1.0"}',
          200,
        ));

        // Act
        final result = await PrivacyService.getPrivacyPolicy();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['content'], 'Privacy policy content');
        expect(result['version'], '1.0');
      });

      test('should throw exception when API call fails', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        // Act & Assert
        expect(
          () => PrivacyService.getPrivacyPolicy(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getTermsOfService', () {
      test('should return terms of service when API call is successful', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"content": "Terms of service content", "version": "1.0"}',
          200,
        ));

        // Act
        final result = await PrivacyService.getTermsOfService();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['content'], 'Terms of service content');
        expect(result['version'], '1.0');
      });
    });
  });
} 