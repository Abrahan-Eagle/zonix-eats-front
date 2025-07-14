import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix_eats_front/lib/features/services/export_service.dart';
import 'package:zonix_eats_front/lib/helpers/auth_helper.dart';

import 'export_service_test.mocks.dart';

@GenerateMocks([http.Client, AuthHelper])
void main() {
  group('ExportService', () {
    late MockClient mockClient;
    late MockAuthHelper mockAuthHelper;

    setUp(() {
      mockClient = MockClient();
      mockAuthHelper = MockAuthHelper();
    });

    group('requestDataExport', () {
      test('should return export request result when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"export_id": "123", "status": "processing"}',
          200,
        ));

        // Act
        final result = await ExportService.requestDataExport();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['export_id'], '123');
        expect(result['status'], 'processing');
      });

      test('should include custom data types and format', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"export_id": "123"}', 200));

        // Act
        await ExportService.requestDataExport(
          dataTypes: ['profile', 'orders'],
          format: 'csv',
        );

        // Assert
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: argThat(
            predicate((String body) => 
              body.contains('"data_types":["profile","orders"]') &&
              body.contains('"format":"csv"')
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
          () => ExportService.requestDataExport(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getExportStatus', () {
      test('should return export status when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"status": "completed", "progress": 100}',
          200,
        ));

        // Act
        final result = await ExportService.getExportStatus('123');

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['status'], 'completed');
        expect(result['progress'], 100);
      });
    });

    group('downloadExport', () {
      test('should return file content when download is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('file content', 200));

        // Act
        final result = await ExportService.downloadExport('123');

        // Assert
        expect(result, 'file content');
      });

      test('should throw exception when download fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Error', 404));

        // Act & Assert
        expect(
          () => ExportService.downloadExport('123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getExportHistory', () {
      test('should return export history when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        when(mockAuthHelper.getToken()).thenAnswer((_) async => token);
        
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data": [{"id": "123", "status": "completed"}]}',
          200,
        ));

        // Act
        final result = await ExportService.getExportHistory();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result.first['id'], '123');
        expect(result.first['status'], 'completed');
      });
    });
  });
} 