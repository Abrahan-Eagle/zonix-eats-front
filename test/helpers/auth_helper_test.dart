import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/helpers/auth_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthHelper Tests', () {
    test('AuthHelper should have storage instance', () {
      // Verificar que AuthHelper tiene una instancia de storage
      expect(AuthHelper.storage, isNotNull);
    });

    test('AuthHelper should have correct structure', () {
      // Verificar que AuthHelper tiene la estructura correcta
      expect(AuthHelper.storage, isNotNull);
      expect(AuthHelper.getAuthHeaders, isA<Function>());
    });

    test('AuthHelper should be properly initialized', () {
      // Verificar que AuthHelper se inicializa correctamente
      expect(AuthHelper.storage, isNotNull);
    });
  });
} 