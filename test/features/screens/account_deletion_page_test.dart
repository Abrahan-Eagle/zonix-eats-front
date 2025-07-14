import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix_eats_front/lib/features/screens/account_deletion_page.dart';
import 'package:zonix_eats_front/lib/features/services/account_deletion_service.dart';

import 'account_deletion_page_test.mocks.dart';

@GenerateMocks([AccountDeletionService])
void main() {
  group('AccountDeletionPage', () {
    late MockAccountDeletionService mockAccountDeletionService;

    setUp(() {
      mockAccountDeletionService = MockAccountDeletionService();
    });

    testWidgets('should display warning card', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Advertencia importante'), findsOneWidget);
      expect(
        find.textContaining('La eliminación de tu cuenta es permanente'),
        findsOneWidget,
      );
    });

    testWidgets('should display deletion request form when no pending request', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': false},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Solicitar eliminación de cuenta'), findsOneWidget);
      expect(find.text('Razón de eliminación *'), findsOneWidget);
      expect(find.text('Comentarios (opcional)'), findsOneWidget);
      expect(find.text('Eliminación inmediata'), findsOneWidget);
      expect(find.text('Solicitar Eliminación'), findsOneWidget);
    });

    testWidgets('should display pending request card when request exists', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {
          'has_pending_request': true,
          'status': 'pending',
          'requested_at': '2024-01-01T10:00:00Z',
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Solicitud pendiente'), findsOneWidget);
      expect(find.text('Tienes una solicitud de eliminación pendiente'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('should show reason dropdown options', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': false},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Razón de eliminación *'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ya no uso la aplicación'), findsOneWidget);
      expect(find.text('Problemas con el servicio'), findsOneWidget);
      expect(find.text('Preocupaciones de privacidad'), findsOneWidget);
      expect(find.text('Creé una nueva cuenta'), findsOneWidget);
      expect(find.text('Otro'), findsOneWidget);
    });

    testWidgets('should request deletion when form is submitted', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': false},
      );
      when(mockAccountDeletionService.requestAccountDeletion()).thenAnswer(
        (_) async => {'deletion_id': '123', 'status': 'pending'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Select reason
      await tester.tap(find.text('Razón de eliminación *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya no uso la aplicación'));
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Solicitar Eliminación'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAccountDeletionService.requestAccountDeletion(
        reason: 'Ya no uso la aplicación',
        feedback: null,
        immediate: false,
      )).called(1);
      expect(find.text('Solicitud de eliminación enviada'), findsOneWidget);
    });

    testWidgets('should show error when no reason is selected', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': false},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Solicitar Eliminación'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Selecciona una razón para la eliminación'), findsOneWidget);
    });

    testWidgets('should cancel deletion request when cancel button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': true},
      );
      when(mockAccountDeletionService.cancelDeletionRequest()).thenAnswer(
        (_) async => {'status': 'cancelled'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAccountDeletionService.cancelDeletionRequest()).called(1);
      expect(find.text('Solicitud de eliminación cancelada'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when confirm button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': true},
      );
      when(mockAccountDeletionService.confirmAccountDeletion()).thenAnswer(
        (_) async => {'status': 'deleted'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Confirmar eliminación'), findsOneWidget);
      expect(find.text('Código de confirmación'), findsOneWidget);
      expect(find.text('Contraseña actual'), findsOneWidget);
    });

    testWidgets('should confirm deletion when form is submitted', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': true},
      );
      when(mockAccountDeletionService.confirmAccountDeletion()).thenAnswer(
        (_) async => {'status': 'deleted'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Fill confirmation form
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAccountDeletionService.confirmAccountDeletion(
        confirmationCode: '123456',
        password: 'password123',
      )).called(1);
      expect(find.text('Cuenta eliminada correctamente'), findsOneWidget);
    });

    testWidgets('should show error when confirmation code is missing', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': true},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ingresa el código de confirmación'), findsOneWidget);
    });

    testWidgets('should show error when password is missing', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': true},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('should display what gets deleted section', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': false},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('¿Qué se elimina?'), findsOneWidget);
      expect(find.text('• Tu perfil y información personal'), findsOneWidget);
      expect(find.text('• Historial completo de pedidos'), findsOneWidget);
      expect(find.text('• Reseñas y calificaciones'), findsOneWidget);
      expect(find.text('• Direcciones guardadas'), findsOneWidget);
      expect(find.text('• Configuraciones de la app'), findsOneWidget);
      expect(find.text('• Datos de actividad'), findsOneWidget);
    });

    testWidgets('should handle error when loading status fails', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenThrow(
        Exception('Network error'),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar estado: Exception: Network error'), findsOneWidget);
    });

    testWidgets('should handle error when request fails', (WidgetTester tester) async {
      // Arrange
      when(mockAccountDeletionService.getDeletionStatus()).thenAnswer(
        (_) async => {'has_pending_request': false},
      );
      when(mockAccountDeletionService.requestAccountDeletion()).thenThrow(
        Exception('Request failed'),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const AccountDeletionPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Select reason and submit
      await tester.tap(find.text('Razón de eliminación *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya no uso la aplicación'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solicitar Eliminación'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al solicitar eliminación: Exception: Request failed'), findsOneWidget);
    });
  });
} 