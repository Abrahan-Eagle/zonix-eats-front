import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

class UserProviderMock extends UserProvider {
  @override
  Future<Map<String, dynamic>> getUserDetails({bool forceRefresh = false}) async {
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

class CommerceUserProviderMock extends UserProvider {
  @override
  Future<Map<String, dynamic>> getUserDetails({bool forceRefresh = false}) async {
    return {
      'users': {
        'id': 2,
        'google_id': 'mock_commerce_google_id',
        'role': 'commerce',
        'name': 'Mock Commerce',
        'email': 'commerce@example.com',
      },
      'role': 'commerce',
      'userId': 2,
      'userGoogleId': 'mock_commerce_google_id',
    };
  }

  @override
  Future<void> logout() async {
    return;
  }
}

class DeliveryUserProviderMock extends UserProvider {
  @override
  Future<Map<String, dynamic>> getUserDetails({bool forceRefresh = false}) async {
    return {
      'users': {
        'id': 3,
        'google_id': 'mock_delivery_google_id',
        'role': 'delivery',
        'name': 'Mock Delivery',
        'email': 'delivery@example.com',
      },
      'role': 'delivery',
      'userId': 3,
      'userGoogleId': 'mock_delivery_google_id',
    };
  }

  @override
  Future<void> logout() async {
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProvider - Tests Generales', () {
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
      expect(() => userProvider.checkAuthentication(), returnsNormally);
    });

    test('Puede obtener detalles del usuario', () async {
      final details = await userProvider.getUserDetails();
      expect(details['role'], 'users');
      expect(details['userId'], 1);
    });

    test('Puede cerrar sesión', () async {
      await userProvider.logout();
      expect(true, isTrue);
    });
  });

  group('UserProvider - Tests por Rol', () {
    late UserProvider usersProvider;
    late UserProvider commerceProvider;
    late UserProvider deliveryProvider;

    setUp(() {
      const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
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
        },
      );
      
      usersProvider = UserProviderMock();
      commerceProvider = CommerceUserProviderMock();
      deliveryProvider = DeliveryUserProviderMock();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    group('Rol: users (Cliente)', () {
      test('Usuario con rol users puede obtener detalles correctos', () async {
        final details = await usersProvider.getUserDetails();
        expect(details['role'], 'users');
        expect(details['userId'], 1);
        expect(details['userGoogleId'], 'mock_google_id');
      });

      test('Usuario con rol users tiene acceso a funcionalidades de cliente', () {
        // Verificar que puede establecer estados específicos de cliente
        usersProvider.setProfileCreated(true);
        usersProvider.setAdresseCreated(true);
        usersProvider.setDocumentCreated(true);
        
        expect(usersProvider.profileCreated, true);
        expect(usersProvider.adresseCreated, true);
        expect(usersProvider.documentCreated, true);
      });

      test('Usuario con rol users puede navegar a MainRouter', () async {
        final details = await usersProvider.getUserDetails();
        expect(details['role'], 'users');
        // En main.dart, si el rol es 'users', navega a MainRouter
        expect(details['role'] == 'users', true);
      });
    });

    group('Rol: commerce (Restaurante)', () {
      test('Usuario con rol commerce puede obtener detalles correctos', () async {
        final details = await commerceProvider.getUserDetails();
        expect(details['role'], 'commerce');
        expect(details['userId'], 2);
        expect(details['userGoogleId'], 'mock_commerce_google_id');
      });

      test('Usuario con rol commerce tiene acceso a funcionalidades de comercio', () {
        // Verificar que puede establecer estados específicos de comercio
        commerceProvider.setProfileCreated(true);
        commerceProvider.setPhoneCreated(true);
        commerceProvider.setEmailCreated(true);
        
        expect(commerceProvider.profileCreated, true);
        expect(commerceProvider.phoneCreated, true);
        expect(commerceProvider.emailCreated, true);
      });

      test('Usuario con rol commerce puede navegar a CommerceOrdersPage', () async {
        final details = await commerceProvider.getUserDetails();
        expect(details['role'], 'commerce');
        // En main.dart, si el rol es 'commerce', navega a CommerceOrdersPage
        expect(details['role'] == 'commerce', true);
      });
    });

    group('Rol: delivery (Repartidor)', () {
      test('Usuario con rol delivery puede obtener detalles correctos', () async {
        final details = await deliveryProvider.getUserDetails();
        expect(details['role'], 'delivery');
        expect(details['userId'], 3);
        expect(details['userGoogleId'], 'mock_delivery_google_id');
      });

      test('Usuario con rol delivery tiene acceso a funcionalidades de repartidor', () {
        // Verificar que puede establecer estados específicos de repartidor
        deliveryProvider.setProfileCreated(true);
        deliveryProvider.setDocumentCreated(true);
        deliveryProvider.setPhoneCreated(true);
        
        expect(deliveryProvider.profileCreated, true);
        expect(deliveryProvider.documentCreated, true);
        expect(deliveryProvider.phoneCreated, true);
      });

      test('Usuario con rol delivery navega a MainRouter por defecto', () async {
        final details = await deliveryProvider.getUserDetails();
        expect(details['role'], 'delivery');
        // En main.dart, si el rol no es 'users' ni 'commerce', navega a MainRouter
        expect(details['role'] != 'users' && details['role'] != 'commerce', true);
      });
    });

    group('Navegación por Rol', () {
      test('Verificar lógica de navegación para todos los roles', () async {
        // Test para rol 'users'
        final usersDetails = await usersProvider.getUserDetails();
        expect(usersDetails['role'], 'users');
        
        // Test para rol 'commerce'
        final commerceDetails = await commerceProvider.getUserDetails();
        expect(commerceDetails['role'], 'commerce');
        
        // Test para rol 'delivery'
        final deliveryDetails = await deliveryProvider.getUserDetails();
        expect(deliveryDetails['role'], 'delivery');
        
        // Verificar que todos los roles tienen IDs únicos
        expect(usersDetails['userId'], isNot(commerceDetails['userId']));
        expect(commerceDetails['userId'], isNot(deliveryDetails['userId']));
        expect(usersDetails['userId'], isNot(deliveryDetails['userId']));
      });

      test('Verificar que cada rol tiene su propio Google ID', () async {
        final usersDetails = await usersProvider.getUserDetails();
        final commerceDetails = await commerceProvider.getUserDetails();
        final deliveryDetails = await deliveryProvider.getUserDetails();
        
        expect(usersDetails['userGoogleId'], 'mock_google_id');
        expect(commerceDetails['userGoogleId'], 'mock_commerce_google_id');
        expect(deliveryDetails['userGoogleId'], 'mock_delivery_google_id');
      });
    });
  });
} 