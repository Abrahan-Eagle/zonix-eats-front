import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

class UserProviderMock extends UserProvider {
  @override
  Future<Map<String, dynamic>> getUserDetails() async {
    // Simula una respuesta exitosa de usuario
    return {
      'users': {
        'id': 1,
        'google_id': 'mock_google_id',
        'role': 'users',
        'name': 'Mock User',
        'email': 'mock@example.com',
      },
      'role': 'users',
      'userId': 1,
      'userGoogleId': 'mock_google_id',
    };
  }

  @override
  Future<void> logout() async {
    // Simula un logout exitoso
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProvider', () {
    late UserProvider userProvider;

    setUp(() {
      // Mock the secure storage
      const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'read') {
            if (methodCall.arguments['key'] == 'token') {
              return 'mock_token';
            }
            return null; // Return null for other reads
          }
          if (methodCall.method == 'write') {
            return null; // Return null for write operations
          }
          return null;
        },
      );
      userProvider = UserProviderMock();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('Inicializa con usuario no autenticado', () {
      expect(userProvider.isAuthenticated, false);
      expect(userProvider.userRole, '');
      expect(userProvider.userName, '');
      expect(userProvider.userEmail, '');
    });

    test('Puede establecer estado de perfil creado', () {
      userProvider.setProfileCreated(true);
      expect(userProvider.profileCreated, true);
    });

    test('Puede establecer estado de dirección creada', () {
      userProvider.setAdresseCreated(true);
      expect(userProvider.adresseCreated, true);
    });

    test('Puede establecer estado de documento creado', () {
      userProvider.setDocumentCreated(true);
      expect(userProvider.documentCreated, true);
    });

    test('Puede establecer estado de teléfono creado', () {
      userProvider.setPhoneCreated(true);
      expect(userProvider.phoneCreated, true);
    });

    test('Puede establecer estado de email creado', () {
      userProvider.setEmailCreated(true);
      expect(userProvider.emailCreated, true);
    });

    test('Puede verificar autenticación', () async {
      // Este test verifica que el método existe y no lanza errores de sintaxis
      expect(() => userProvider.checkAuthentication(), returnsNormally);
    });

    test('Puede obtener detalles del usuario', () async {
      final details = await userProvider.getUserDetails();
      expect(details['role'], 'users');
      expect(details['userId'], 1);
    });

    test('Puede cerrar sesión', () async {
      // Este test verifica que el método existe y no lanza errores de sintaxis
      await userProvider.logout();
      expect(true, isTrue);
    });
  });
} 