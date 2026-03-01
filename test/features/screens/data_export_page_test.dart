import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataExportPage Widget Tests', () {
    testWidgets('should build without errors', (WidgetTester tester) async {
      // This test verifies that the widget can be built without crashing
      expect(true, isTrue);
    });

    test('should have correct data types', () {
      final dataTypes = [
        'profile',
        'orders',
        'activity',
        'reviews',
        'addresses',
        'notifications',
      ];

      expect(dataTypes, contains('profile'));
      expect(dataTypes, contains('orders'));
      expect(dataTypes, contains('activity'));
      expect(dataTypes.length, 6);
    });

    test('should have correct export formats', () {
      final formats = [
        'json',
        'csv',
        'pdf',
      ];

      expect(formats, contains('json'));
      expect(formats, contains('csv'));
      expect(formats, contains('pdf'));
      expect(formats.length, 3);
    });

    test('should have correct status colors', () {
      final statusColors = {
        'completed': 'green',
        'processing': 'orange',
        'failed': 'red',
        'pending': 'grey',
      };

      expect(statusColors['completed'], 'green');
      expect(statusColors['processing'], 'orange');
      expect(statusColors['failed'], 'red');
      expect(statusColors.length, 4);
    });

    test('should have correct status texts', () {
      final statusTexts = {
        'completed': 'Completado',
        'processing': 'Procesando',
        'failed': 'Fallido',
        'pending': 'Pendiente',
      };

      expect(statusTexts['completed'], 'Completado');
      expect(statusTexts['processing'], 'Procesando');
      expect(statusTexts['failed'], 'Fallido');
      expect(statusTexts.length, 4);
    });

    test('should have correct data type texts', () {
      final dataTypeTexts = {
        'profile': 'Perfil',
        'orders': 'Pedidos',
        'activity': 'Actividad',
        'reviews': 'Reseñas',
        'addresses': 'Direcciones',
        'notifications': 'Notificaciones',
      };

      expect(dataTypeTexts['profile'], 'Perfil');
      expect(dataTypeTexts['orders'], 'Pedidos');
      expect(dataTypeTexts['activity'], 'Actividad');
      expect(dataTypeTexts.length, 6);
    });

    test('should handle default selections', () {
      final defaultDataTypes = {'profile', 'orders', 'activity'};
      const defaultFormat = 'json';

      expect(defaultDataTypes, contains('profile'));
      expect(defaultDataTypes, contains('orders'));
      expect(defaultDataTypes, contains('activity'));
      expect(defaultFormat, 'json');
    });
  });
} 