import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/config/app_config.dart';

/// [AppConfig.appLinkBase] depende de `.env`; cada test fuerza un [testLoad] aislado.
void main() {
  group('AppConfig.appLinkBase', () {
    test('APP_LINK_BASE tiene prioridad sobre todo', () {
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=development
APP_LINK_BASE=https://override.example.com
APP_LINK_BASE_LOCAL=https://dev.example.com
APP_LINK_BASE_PROD=https://prod.example.com
''');
      expect(AppConfig.appLinkBase, 'https://override.example.com');
    });

    test('ENVIRONMENT=development usa APP_LINK_BASE_LOCAL', () {
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=development
APP_LINK_BASE_LOCAL=https://local.example.com
''');
      expect(AppConfig.appLinkBase, 'https://local.example.com');
    });

    test('ENVIRONMENT=staging usa APP_LINK_BASE_STAGING', () {
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=staging
APP_LINK_BASE_STAGING=https://staging.example.com
''');
      expect(AppConfig.appLinkBase, 'https://staging.example.com');
    });

    test('ENVIRONMENT=test usa APP_LINK_BASE_TEST', () {
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=test
APP_LINK_BASE_TEST=https://test.example.com
''');
      expect(AppConfig.appLinkBase, 'https://test.example.com');
    });

    test('ENVIRONMENT=production usa APP_LINK_BASE_PROD', () {
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=production
APP_LINK_BASE_PROD=https://prod.example.com
''');
      expect(AppConfig.appLinkBase, 'https://prod.example.com');
    });

    test('APP_LINK_BASE_DEV alias de desarrollo', () {
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=dev
APP_LINK_BASE_DEV=https://dev-alias.example.com
''');
      expect(AppConfig.appLinkBase, 'https://dev-alias.example.com');
    });
  });
}
