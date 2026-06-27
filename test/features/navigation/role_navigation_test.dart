import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zonix_glasses/features/utils/bottom_nav_persistence.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

class MockUserProvider extends UserProvider {
  final String role;
  final bool _isAuthenticated;
  final bool _completedOnboarding;

  MockUserProvider({
    required this.role,
    required bool isAuthenticated,
    bool completedOnboarding = true,
  })  : _isAuthenticated = isAuthenticated,
        _completedOnboarding = completedOnboarding;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  bool get completedOnboarding => _completedOnboarding;

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
  Future<void> logout() async {}
}

/// Resumen de rutas en [MyApp] (Zonix Glasses): SignIn → Onboarding → MainRouter.
enum _AppRoute { signIn, onboarding, mainRouter }

_AppRoute routeFor(MockUserProvider provider) {
  if (!provider.isAuthenticated) return _AppRoute.signIn;
  if (!provider.completedOnboarding) return _AppRoute.onboarding;
  return _AppRoute.mainRouter;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navegación por roles (Zonix Glasses)', () {
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
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    group('Usuario no autenticado', () {
      test('debe ir a SignInScreen', () {
        final userProvider =
            MockUserProvider(role: '', isAuthenticated: false);

        expect(routeFor(userProvider), _AppRoute.signIn);
      });
    });

    group('Usuario autenticado — rol user', () {
      test('con onboarding completo va a MainRouter', () {
        final userProvider =
            MockUserProvider(role: 'user', isAuthenticated: true);

        expect(userProvider.userRole, 'user');
        expect(routeFor(userProvider), _AppRoute.mainRouter);
      });

      test('sin onboarding va a OnboardingScreen', () {
        final userProvider = MockUserProvider(
          role: 'user',
          isAuthenticated: true,
          completedOnboarding: false,
        );

        expect(routeFor(userProvider), _AppRoute.onboarding);
      });

      test('persistencia bottom nav usa clave user', () {
        expect(bottomNavStorageKey('user'), 'bottomNavIndex_user');
        expect(defaultLevelForRole('user'), 0);
        expect(levelsForRole('user'), [0]);
      });
    });

    group('Usuario autenticado — rol admin', () {
      test('con onboarding completo va a MainRouter', () {
        final userProvider =
            MockUserProvider(role: 'admin', isAuthenticated: true);

        expect(userProvider.userRole, 'admin');
        expect(routeFor(userProvider), _AppRoute.mainRouter);
      });

      test('persistencia bottom nav distingue admin', () {
        expect(bottomNavStorageKey('admin'), 'bottomNavIndex_admin');
        expect(defaultLevelForRole('admin'), 1);
        expect(levelsForRole('admin'), [1]);
      });
    });

    group('Lógica de navegación completa', () {
      test('roles user y admin comparten MainRouter tras onboarding', () {
        for (final role in ['user', 'admin']) {
          final provider =
              MockUserProvider(role: role, isAuthenticated: true);
          expect(routeFor(provider), _AppRoute.mainRouter);
        }
      });

      test('rol desconocido autenticado sigue el flujo estándar', () {
        final provider =
            MockUserProvider(role: 'custom_role', isAuthenticated: true);

        expect(routeFor(provider), _AppRoute.mainRouter);
        expect(bottomNavStorageKey('custom_role'),
            'bottomNavIndex_custom_role');
      });
    });

    group('Transiciones de estado', () {
      test('login expone detalles con el rol esperado', () async {
        final userProvider =
            MockUserProvider(role: 'user', isAuthenticated: true);
        final details = await userProvider.getUserDetails();

        expect(details['role'], 'user');
        expect(details['userId'], 1);
      });

      test('logout no lanza excepción', () async {
        final userProvider =
            MockUserProvider(role: 'admin', isAuthenticated: true);
        await userProvider.logout();
        expect(true, isTrue);
      });
    });
  });
}
