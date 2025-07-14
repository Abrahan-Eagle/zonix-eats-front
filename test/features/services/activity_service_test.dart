import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/services/activity_service.dart';

void main() {
  group('ActivityService', () {
    group('getUserActivityHistory', () {
      test('should throw exception when token is null', () async {
        // Act & Assert
        expect(
          () => ActivityService.getUserActivityHistory(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getActivityStats', () {
      test('should throw exception when token is null', () async {
        // Act & Assert
        expect(
          () => ActivityService.getActivityStats(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
} 