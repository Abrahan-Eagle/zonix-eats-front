import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'package:zonix/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Cargar dotenv para tests: si no hay .env, usar valores de prueba para que AppConfig no devuelva vacío
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: 'API_URL=http://test.example.com\n');
    }
  });

  group('AuthHelper Integration Tests', () {
    test('AppConfig should have apiUrl', () {
      expect(AppConfig.apiUrl, isNotEmpty);
      expect(AppConfig.apiUrl, contains('http'));
    });

    test('AuthHelper getAuthHeaders should return Future<Map<String, String>>', () async {
      final headers = await AuthHelper.getAuthHeaders();
      expect(headers, isA<Map<String, String>>());
      expect(headers['Authorization'], isNotEmpty);
    }, skip: 'Requiere plugins de plataforma en test');
  });
} 