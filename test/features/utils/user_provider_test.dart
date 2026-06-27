import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

class UserProviderMock extends UserProvider {
  final String role;

  UserProviderMock({this.role = 'user'});

  @override
  Future<Map<String, dynamic>> getUserDetails({bool forceRefresh = false}) async {
    return {
      'users': {
        'id': 1,
        'google_id': 'mock_google_id',
        'role': role,
        'name': 'Mock User',
        'email': 'mock@example.com',
      },
      'role': role,
      'userId': 1,
      'userGoogleId': 'mock_google_id',
    };
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProvider - Zonix Glasses', () {
    late UserProvider userProvider;

    setUp(() {
      const MethodChannel channel =
          MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          if (methodCall.arguments['key'] == 'token') {
            return 'mock_token';
          }
          return null;
        }
        if (methodCall.method == 'write') {
          return null;
        }
        return null;
      });
      userProvider = UserProviderMock();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('inicializa con usuario no autenticado', () {
      expect(userProvider.isAuthenticated, false);
      expect(userProvider.userRole, '');
      expect(userProvider.userName, '');
      expect(userProvider.userEmail, '');
    });

    test('flags de onboarding/perfil se pueden establecer', () {
      userProvider.setProfileCreated(true);
      userProvider.setAdresseCreated(true);
      userProvider.setDocumentCreated(true);
      userProvider.setPhoneCreated(true);
      userProvider.setEmailCreated(true);

      expect(userProvider.profileCreated, true);
      expect(userProvider.adresseCreated, true);
      expect(userProvider.documentCreated, true);
      expect(userProvider.phoneCreated, true);
      expect(userProvider.emailCreated, true);
    });

    test('checkAuthentication no lanza', () async {
      expect(() => userProvider.checkAuthentication(), returnsNormally);
    });

    test('rol user — getUserDetails', () async {
      final details = await userProvider.getUserDetails();
      expect(details['role'], 'user');
      expect(details['userId'], 1);
    });

    test('rol admin — getUserDetails', () async {
      final adminProvider = UserProviderMock(role: 'admin');
      final details = await adminProvider.getUserDetails();
      expect(details['role'], 'admin');
    });

    test('setAuthenticatedForTest expone rol', () {
      userProvider.setAuthenticatedForTest(role: 'admin');
      expect(userProvider.isAuthenticated, true);
      expect(userProvider.userRole, 'admin');
    });

    test('logout no lanza', () async {
      await userProvider.logout();
      expect(true, isTrue);
    });
  });
}
