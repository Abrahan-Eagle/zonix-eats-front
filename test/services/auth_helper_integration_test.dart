import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'package:zonix/features/services/test_auth_service.dart';
import 'package:zonix/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthHelper Integration Tests', () {
    test('AuthHelper should have correct structure', () {
      // Verificar que AuthHelper tiene la estructura correcta
      expect(AuthHelper.storage, isNotNull);
    });

    test('TestAuthService should have correct structure', () {
      // Verificar que TestAuthService tiene la estructura correcta
      expect(TestAuthService.testAuth, isNotNull);
    });

    test('AppConfig should have baseUrl', () {
      // Verificar que AppConfig tiene la URL base configurada
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.baseUrl, contains('http'));
    });

    test('AuthHelper getAuthHeaders should return Future<Map<String, String>>', () {
      // Verificar que getAuthHeaders devuelve el tipo correcto
      final result = AuthHelper.getAuthHeaders();
      expect(result, isA<Future<Map<String, String>>>());
    });

    test('TestAuthService testAuth should return Future<Map<String, dynamic>>', () {
      // Verificar que testAuth devuelve el tipo correcto
      final result = TestAuthService.testAuth();
      expect(result, isA<Future<Map<String, dynamic>>>());
    });
  });
} 