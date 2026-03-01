import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/services/activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    // Mock secure storage para evitar errores de binding
    const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'read' && methodCall.arguments['key'] == 'token') {
          // Simular que no hay token (null)
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    // Limpiar mock handlers después de cada test
    const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  group('ActivityService', () {
    group('getUserActivityHistory', () {
      test('should throw exception when token is null', () async {
        // Act & Assert
        expect(
          () async => await ActivityService.getUserActivityHistory(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getActivityStats', () {
      test('should throw exception when token is null', () async {
        // Act & Assert
        expect(
          () async => await ActivityService.getActivityStats(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
} 