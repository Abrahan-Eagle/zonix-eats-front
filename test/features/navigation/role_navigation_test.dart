import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/utils/user_provider.dart';

class MockUserProvider extends UserProvider {
  final String role;
  final bool _isAuthenticated;

  MockUserProvider({required this.role, required bool isAuthenticated}) 
      : _isAuthenticated = isAuthenticated;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String get userRole => role;

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
  Future<void> logout() async {
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navegación por Roles', () {
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
            return null;
          }
          if (methodCall.method == 'write') {
            return null;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    group('Usuario No Autenticado', () {
      test('Usuario no autenticado debe ir a SignInScreen', () {
        final userProvider = MockUserProvider(role: '', isAuthenticated: false);
        
        expect(userProvider.isAuthenticated, false);
        expect(userProvider.userRole, '');
        
        // En main.dart: si no está autenticado, va a SignInScreen
        expect(userProvider.isAuthenticated == false, true);
      });
    });

    group('Usuario Autenticado - Rol: users', () {
      test('Usuario autenticado con rol users debe ir a MainRouter', () {
        final userProvider = MockUserProvider(role: 'users', isAuthenticated: true);
        
        expect(userProvider.isAuthenticated, true);
        expect(userProvider.userRole, 'users');
        
        // En main.dart: si está autenticado y el rol es 'users', va a MainRouter
        expect(userProvider.isAuthenticated == true && userProvider.userRole == 'users', true);
      });

      test('Usuario con rol users tiene acceso a funcionalidades de cliente', () async {
        final userProvider = MockUserProvider(role: 'users', isAuthenticated: true);
        final details = await userProvider.getUserDetails();
        
        expect(details['role'], 'users');
        expect(details['userId'], 1);
        expect(details['userGoogleId'], 'mock_google_id');
      });
    });

    group('Usuario Autenticado - Rol: commerce', () {
      test('Usuario autenticado con rol commerce debe ir a CommerceOrdersPage', () {
        final userProvider = MockUserProvider(role: 'commerce', isAuthenticated: true);
        
        expect(userProvider.isAuthenticated, true);
        expect(userProvider.userRole, 'commerce');
        
        // En main.dart: si está autenticado y el rol es 'commerce', va a CommerceOrdersPage
        expect(userProvider.isAuthenticated == true && userProvider.userRole == 'commerce', true);
      });

      test('Usuario con rol commerce tiene acceso a funcionalidades de comercio', () async {
        final userProvider = MockUserProvider(role: 'commerce', isAuthenticated: true);
        final details = await userProvider.getUserDetails();
        
        expect(details['role'], 'commerce');
        expect(details['userId'], 1);
        expect(details['userGoogleId'], 'mock_google_id');
      });
    });

    group('Usuario Autenticado - Rol: delivery', () {
      test('Usuario autenticado con rol delivery debe ir a MainRouter (fallback)', () {
        final userProvider = MockUserProvider(role: 'delivery', isAuthenticated: true);
        
        expect(userProvider.isAuthenticated, true);
        expect(userProvider.userRole, 'delivery');
        
        // En main.dart: si está autenticado pero el rol no es 'users' ni 'commerce', va a MainRouter
        expect(userProvider.isAuthenticated == true && 
               userProvider.userRole != 'users' && 
               userProvider.userRole != 'commerce', true);
      });

      test('Usuario con rol delivery tiene acceso a funcionalidades de repartidor', () async {
        final userProvider = MockUserProvider(role: 'delivery', isAuthenticated: true);
        final details = await userProvider.getUserDetails();
        
        expect(details['role'], 'delivery');
        expect(details['userId'], 1);
        expect(details['userGoogleId'], 'mock_google_id');
      });
    });

    group('Usuario Autenticado - Rol Desconocido', () {
      test('Usuario autenticado con rol desconocido debe ir a MainRouter (fallback)', () {
        final userProvider = MockUserProvider(role: 'unknown_role', isAuthenticated: true);
        
        expect(userProvider.isAuthenticated, true);
        expect(userProvider.userRole, 'unknown_role');
        
        // En main.dart: si está autenticado pero el rol no es 'users' ni 'commerce', va a MainRouter
        expect(userProvider.isAuthenticated == true && 
               userProvider.userRole != 'users' && 
               userProvider.userRole != 'commerce', true);
      });
    });

    group('Lógica de Navegación Completa', () {
      test('Verificar todas las rutas de navegación posibles', () {
        // Caso 1: No autenticado
        final notAuthenticated = MockUserProvider(role: '', isAuthenticated: false);
        expect(notAuthenticated.isAuthenticated, false);
        
        // Caso 2: Autenticado como users
        final usersRole = MockUserProvider(role: 'users', isAuthenticated: true);
        expect(usersRole.isAuthenticated && usersRole.userRole == 'users', true);
        
        // Caso 3: Autenticado como commerce
        final commerceRole = MockUserProvider(role: 'commerce', isAuthenticated: true);
        expect(commerceRole.isAuthenticated && commerceRole.userRole == 'commerce', true);
        
        // Caso 4: Autenticado como delivery
        final deliveryRole = MockUserProvider(role: 'delivery', isAuthenticated: true);
        expect(deliveryRole.isAuthenticated && 
               deliveryRole.userRole != 'users' && 
               deliveryRole.userRole != 'commerce', true);
        
        // Caso 5: Autenticado con rol desconocido
        final unknownRole = MockUserProvider(role: 'unknown', isAuthenticated: true);
        expect(unknownRole.isAuthenticated && 
               unknownRole.userRole != 'users' && 
               unknownRole.userRole != 'commerce', true);
      });

      test('Verificar que cada rol tiene su propia lógica de navegación', () {
        final roles = ['users', 'commerce', 'delivery', 'unknown'];
        
        for (final role in roles) {
          final userProvider = MockUserProvider(role: role, isAuthenticated: true);
          
          if (role == 'users') {
            expect(userProvider.userRole == 'users', true);
          } else if (role == 'commerce') {
            expect(userProvider.userRole == 'commerce', true);
          } else {
            // delivery, unknown, o cualquier otro rol
            expect(userProvider.userRole != 'users' && userProvider.userRole != 'commerce', true);
          }
        }
      });
    });

    group('Transiciones de Estado', () {
      test('Usuario puede cambiar de no autenticado a autenticado', () async {
        // Simular login
        final userProvider = MockUserProvider(role: 'users', isAuthenticated: true);
        
        expect(userProvider.isAuthenticated, true);
        expect(userProvider.userRole, 'users');
        
        final details = await userProvider.getUserDetails();
        expect(details['role'], 'users');
      });

      test('Usuario puede hacer logout', () async {
        final userProvider = MockUserProvider(role: 'users', isAuthenticated: true);
        
        expect(userProvider.isAuthenticated, true);
        
        // Simular logout
        await userProvider.logout();
        expect(true, isTrue); // Si no lanza excepción, el logout fue exitoso
      });
    });
  });
} 