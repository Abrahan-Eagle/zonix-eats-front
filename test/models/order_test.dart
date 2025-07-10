import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/models/order.dart';

void main() {
  group('Order', () {
    test('Crea orden con datos básicos', () {
      final order = Order(
        id: 1,
        status: 'pending',
        total: 25.0,
        items: [],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(order.id, 1);
      expect(order.status, 'pending');
      expect(order.total, 25.0);
      expect(order.items, isEmpty);
      expect(order.createdAt, DateTime(2024, 1, 1));
    });

    test('Crea orden desde JSON', () {
      final json = {
        'id': 1,
        'status': 'pending',
        'total': 25.0,
        'created_at': '2024-01-01T00:00:00.000Z',
        'items': [],
        'comprobante_url': 'https://example.com/comprobante.pdf',
        'estado': 'pendiente',
      };

      final order = Order.fromJson(json);

      expect(order.id, 1);
      expect(order.status, 'pending');
      expect(order.total, 25.0);
      expect(order.items, isEmpty);
      expect(order.comprobanteUrl, 'https://example.com/comprobante.pdf');
      expect(order.estado, 'pendiente');
    });

    test('Maneja total como entero en JSON', () {
      final json = {
        'id': 1,
        'status': 'pending',
        'total': 25,
        'created_at': '2024-01-01T00:00:00.000Z',
        'items': [],
      };

      final order = Order.fromJson(json);

      expect(order.total, 25.0);
    });

    test('Maneja total como string en JSON', () {
      final json = {
        'id': 1,
        'status': 'pending',
        'total': '25.50',
        'created_at': '2024-01-01T00:00:00.000Z',
        'items': [],
      };

      final order = Order.fromJson(json);

      expect(order.total, 25.50);
    });
  });

  group('OrderItem', () {
    test('Crea item de orden con datos básicos', () {
      final item = OrderItem(
        id: 1,
        nombre: 'Pizza Margherita',
        quantity: 2,
        precio: 15.0,
      );

      expect(item.id, 1);
      expect(item.nombre, 'Pizza Margherita');
      expect(item.quantity, 2);
      expect(item.precio, 15.0);
    });

    test('Crea item de orden desde JSON', () {
      final json = {
        'id': 1,
        'nombre': 'Pizza Margherita',
        'quantity': 2,
        'precio': 15.0,
      };

      final item = OrderItem.fromJson(json);

      expect(item.id, 1);
      expect(item.nombre, 'Pizza Margherita');
      expect(item.quantity, 2);
      expect(item.precio, 15.0);
    });

    test('Maneja precio como entero en JSON', () {
      final json = {
        'id': 1,
        'nombre': 'Pizza Margherita',
        'quantity': 2,
        'precio': 15,
      };

      final item = OrderItem.fromJson(json);

      expect(item.precio, 15.0);
    });

    test('Maneja precio como string en JSON', () {
      final json = {
        'id': 1,
        'nombre': 'Pizza Margherita',
        'quantity': 2,
        'precio': '15.50',
      };

      final item = OrderItem.fromJson(json);

      expect(item.precio, 15.50);
    });
  });
} 