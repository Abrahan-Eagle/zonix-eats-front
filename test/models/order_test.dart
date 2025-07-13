import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/models/order.dart';

void main() {
  group('Order', () {
    test('Crea orden con datos básicos', () {
      final order = Order(
        id: 1,
        userId: 1,
        commerceId: 1,
        orderNumber: 'ORD-001',
        status: 'pending',
        subtotal: 20.0,
        deliveryFee: 3.0,
        tax: 2.0,
        total: 25.0,
        paymentMethod: 'cash',
        paymentStatus: 'pending',
        deliveryAddress: 'Calle 123',
        estimatedDeliveryTime: DateTime(2024, 1, 1, 13, 0),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        items: [],
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
        'user_id': 1,
        'commerce_id': 1,
        'order_number': 'ORD-001',
        'status': 'pending',
        'subtotal': 20.0,
        'delivery_fee': 3.0,
        'tax': 2.0,
        'total': 25.0,
        'payment_method': 'cash',
        'payment_status': 'pending',
        'delivery_address': 'Calle 123',
        'estimated_delivery_time': '2024-01-01T13:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'items': [],
      };
      final order = Order.fromJson(json);
      expect(order.id, 1);
      expect(order.status, 'pending');
      expect(order.total, 25.0);
      expect(order.items, isEmpty);
      expect(order.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('Maneja total como entero en JSON', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'commerce_id': 1,
        'order_number': 'ORD-001',
        'status': 'pending',
        'subtotal': 20,
        'delivery_fee': 3,
        'tax': 2,
        'total': 25,
        'payment_method': 'cash',
        'payment_status': 'pending',
        'delivery_address': 'Calle 123',
        'estimated_delivery_time': '2024-01-01T13:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'items': [],
      };
      final order = Order.fromJson(json);
      expect(order.total, 25.0);
    });

    test('Maneja total como string en JSON', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'commerce_id': 1,
        'order_number': 'ORD-001',
        'status': 'pending',
        'subtotal': 20,
        'delivery_fee': 3,
        'tax': 2,
        'total': '25.50',
        'payment_method': 'cash',
        'payment_status': 'pending',
        'delivery_address': 'Calle 123',
        'estimated_delivery_time': '2024-01-01T13:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
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
        orderId: 1,
        productId: 1,
        productName: 'Pizza Margherita',
        productImage: 'pizza.jpg',
        price: 15.0,
        quantity: 2,
        total: 30.0,
      );
      expect(item.id, 1);
      expect(item.productName, 'Pizza Margherita');
      expect(item.quantity, 2);
      expect(item.price, 15.0);
      expect(item.total, 30.0);
    });

    test('Crea item de orden desde JSON', () {
      final json = {
        'id': 1,
        'order_id': 1,
        'product_id': 1,
        'product_name': 'Pizza Margherita',
        'product_image': 'pizza.jpg',
        'price': 15.0,
        'quantity': 2,
        'total': 30.0,
      };
      final item = OrderItem.fromJson(json);
      expect(item.id, 1);
      expect(item.productName, 'Pizza Margherita');
      expect(item.quantity, 2);
      expect(item.price, 15.0);
      expect(item.total, 30.0);
    });

    test('Maneja price como entero en JSON', () {
      final json = {
        'id': 1,
        'order_id': 1,
        'product_id': 1,
        'product_name': 'Pizza Margherita',
        'product_image': 'pizza.jpg',
        'price': 15,
        'quantity': 2,
        'total': 30,
      };
      final item = OrderItem.fromJson(json);
      expect(item.price, 15.0);
      expect(item.total, 30.0);
    });

    test('Maneja price como string en JSON', () {
      final json = {
        'id': 1,
        'order_id': 1,
        'product_id': 1,
        'product_name': 'Pizza Margherita',
        'product_image': 'pizza.jpg',
        'price': '15.50',
        'quantity': 2,
        'total': '31.00',
      };
      final item = OrderItem.fromJson(json);
      expect(item.price, 15.50);
      expect(item.total, 31.00);
    });
  });
} 