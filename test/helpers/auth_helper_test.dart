import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/helpers/auth_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthHelper Tests', () {
    test('AuthHelper should have storage instance', () {
      // Verificar que AuthHelper tiene una instancia de storage
      expect(AuthHelper.storage, isNotNull);
    });

    test('AuthHelper should be able to create storage instance', () {
      // Verificar que se puede crear una instancia de FlutterSecureStorage
      const storage = FlutterSecureStorage();
      expect(storage, isNotNull);
    });
  });
} 