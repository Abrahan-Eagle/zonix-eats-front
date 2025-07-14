import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix_eats_front/lib/features/screens/privacy_settings_page.dart';
import 'package:zonix_eats_front/lib/features/services/privacy_service.dart';

import 'privacy_settings_page_test.mocks.dart';

@GenerateMocks([PrivacyService])
void main() {
  group('PrivacySettingsPage', () {
    late MockPrivacyService mockPrivacyService;

    setUp(() {
      mockPrivacyService = MockPrivacyService();
    });

    testWidgets('should display privacy control information', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Controla tu privacidad'), findsOneWidget);
      expect(
        find.textContaining('Gestiona cómo se utilizan y comparten tus datos'),
        findsOneWidget,
      );
    });

    testWidgets('should display profile visibility section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Visibilidad del perfil'), findsOneWidget);
      expect(find.text('Controla quién puede ver tu información personal'), findsOneWidget);
      expect(find.text('Perfil público'), findsOneWidget);
      expect(find.text('Permitir que otros usuarios vean tu perfil'), findsOneWidget);
    });

    testWidgets('should display order history section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Historial de pedidos'), findsOneWidget);
      expect(find.text('Controla la visibilidad de tu historial de compras'), findsOneWidget);
      expect(find.text('Historial visible'), findsOneWidget);
    });

    testWidgets('should display activity section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Actividad'), findsOneWidget);
      expect(find.text('Controla la visibilidad de tu actividad en la app'), findsOneWidget);
      expect(find.text('Actividad visible'), findsOneWidget);
    });

    testWidgets('should display notifications section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Controla cómo recibes notificaciones'), findsOneWidget);
      expect(find.text('Emails de marketing'), findsOneWidget);
      expect(find.text('Notificaciones push'), findsOneWidget);
    });

    testWidgets('should display location section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ubicación'), findsOneWidget);
      expect(find.text('Controla el uso de tu ubicación'), findsOneWidget);
      expect(find.text('Compartir ubicación'), findsOneWidget);
    });

    testWidgets('should display data analytics section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Análisis de datos'), findsOneWidget);
      expect(find.text('Controla el uso de datos para análisis'), findsOneWidget);
      expect(find.text('Análisis de datos'), findsNWidgets(2)); // Title and switch
    });

    testWidgets('should update settings when switch is toggled', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {'profile_visibility': false},
      );
      when(mockPrivacyService.updatePrivacySettings()).thenAnswer(
        (_) async => {'profile_visibility': true},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil público'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockPrivacyService.updatePrivacySettings(
        profileVisibility: true,
      )).called(1);
      expect(find.text('Configuración actualizada'), findsOneWidget);
    });

    testWidgets('should display policies and terms section', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Políticas y términos'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
      expect(find.text('Términos de servicio'), findsOneWidget);
    });

    testWidgets('should show privacy policy when tapped', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );
      when(mockPrivacyService.getPrivacyPolicy()).thenAnswer(
        (_) async => {'content': 'Privacy policy content'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Política de Privacidad'), findsOneWidget);
      expect(find.text('Privacy policy content'), findsOneWidget);
    });

    testWidgets('should show terms of service when tapped', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {},
      );
      when(mockPrivacyService.getTermsOfService()).thenAnswer(
        (_) async => {'content': 'Terms of service content'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Términos de servicio'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Términos de Servicio'), findsOneWidget);
      expect(find.text('Terms of service content'), findsOneWidget);
    });

    testWidgets('should handle error when loading settings fails', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenThrow(
        Exception('Network error'),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar configuración: Exception: Network error'), findsOneWidget);
    });

    testWidgets('should handle error when updating settings fails', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {'profile_visibility': false},
      );
      when(mockPrivacyService.updatePrivacySettings()).thenThrow(
        Exception('Update failed'),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil público'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al actualizar configuración: Exception: Update failed'), findsOneWidget);
    });

    testWidgets('should show loading indicator when saving', (WidgetTester tester) async {
      // Arrange
      when(mockPrivacyService.getPrivacySettings()).thenAnswer(
        (_) async => {'profile_visibility': false},
      );
      when(mockPrivacyService.updatePrivacySettings()).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 1), () => {'profile_visibility': true}),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil público'));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
} 