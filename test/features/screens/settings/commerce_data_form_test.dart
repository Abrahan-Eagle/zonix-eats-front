import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix_eats_front/features/screens/settings/commerce_data_page.dart';
import 'package:zonix_eats_front/features/services/commerce_data_service.dart';

@GenerateMocks([CommerceDataService])
import 'commerce_data_form_test.mocks.dart';

void main() {
  group('CommerceDataPage Widget Tests', () {
    late MockCommerceDataService mockService;

    setUp(() {
      mockService = MockCommerceDataService();
    });

    testWidgets('should display form fields correctly', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      // Wait for the widget to load
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Datos del Comercio'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Test Commerce'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('Test Address'), findsOneWidget);
      expect(find.text('123456789'), findsOneWidget);
      expect(find.text('test@commerce.com'), findsOneWidget);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Try to save without filling required fields
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // Assert
      expect(find.text('El nombre es requerido'), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // Assert
      expect(find.text('Ingresa un email válido'), findsOneWidget);
    });

    testWidgets('should validate phone format', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid phone
      await tester.enterText(find.byKey(const Key('phone_field')), '123');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // Assert
      expect(find.text('El teléfono debe tener al menos 7 dígitos'), findsOneWidget);
    });

    testWidgets('should validate delivery fee is positive', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter negative delivery fee
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '-5');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // Assert
      expect(find.text('La tarifa debe ser mayor o igual a 0'), findsOneWidget);
    });

    testWidgets('should validate minimum order is positive', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter negative minimum order
      await tester.enterText(find.byKey(const Key('minimum_order_field')), '-10');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // Assert
      expect(find.text('El pedido mínimo debe ser mayor o igual a 0'), findsOneWidget);
    });

    testWidgets('should show loading indicator when saving', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);
      when(mockService.updateCommerceProfile(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testData;
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form and save
      await tester.enterText(find.byKey(const Key('name_field')), 'Updated Commerce');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success message when save is successful', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);
      when(mockService.updateCommerceProfile(any)).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form and save
      await tester.enterText(find.byKey(const Key('name_field')), 'Updated Commerce');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Datos actualizados correctamente'), findsOneWidget);
    });

    testWidgets('should show error message when save fails', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);
      when(mockService.updateCommerceProfile(any)).thenThrow(Exception('Update failed'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form and save
      await tester.enterText(find.byKey(const Key('name_field')), 'Updated Commerce');
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al actualizar datos: Update failed'), findsOneWidget);
    });

    testWidgets('should toggle open status correctly', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);
      when(mockService.updateOpenStatus(any)).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle open status
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert
      verify(mockService.updateOpenStatus(false)).called(1);
    });

    testWidgets('should show image picker when image is tapped', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on image
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Seleccionar Imagen'), findsOneWidget);
    });

    testWidgets('should display current image if available', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
        'image_url': 'https://example.com/image.jpg',
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should show error state when loading fails', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenThrow(Exception('Load failed'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar datos'), findsOneWidget);
      expect(find.text('Load failed'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile())
          .thenThrow(Exception('Load failed'))
          .thenAnswer((_) async => {'name': 'Test Commerce'});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Commerce'), findsOneWidget);
    });

    testWidgets('should show empty state when no data is available', (WidgetTester tester) async {
      // Arrange
      when(mockService.getCommerceProfile()).thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No hay datos disponibles'), findsOneWidget);
      expect(find.text('Completa la información de tu comercio'), findsOneWidget);
    });

    testWidgets('should format currency values correctly', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.50,
        'minimum_order': 10.75,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5.50'), findsOneWidget);
      expect(find.text('10.75'), findsOneWidget);
    });

    testWidgets('should handle form reset correctly', (WidgetTester tester) async {
      // Arrange
      const testData = {
        'name': 'Test Commerce',
        'description': 'Test Description',
        'address': 'Test Address',
        'phone': '123456789',
        'email': 'test@commerce.com',
        'is_open': true,
        'delivery_fee': 5.0,
        'minimum_order': 10.0,
      };

      when(mockService.getCommerceProfile()).thenAnswer((_) async => testData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommerceDataPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Modify form
      await tester.enterText(find.byKey(const Key('name_field')), 'Modified Name');
      await tester.enterText(find.byKey(const Key('description_field')), 'Modified Description');

      // Tap reset button
      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Commerce'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });
  });
} 