import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'package:zonix/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Mock dotenv para evitar NotInitializedError
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  });
  
  group('AuthHelper Integration Tests', () {
      test('AppConfig should have apiUrl', () {
    expect(AppConfig.apiUrl, isNotEmpty);
  });

    test('AuthHelper getAuthHeaders should return Future<Map<String, String>>', () async {
      final headers = await AuthHelper.getAuthHeaders();
      expect(headers, isA<Map<String, String>>());
      expect(headers['Authorization'], isNotEmpty);
    }, skip: 'Requiere plugins de plataforma en test');
  });
} 