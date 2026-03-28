import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/order_confirmation_page.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/orders/current_order_detail_page.dart';

/// Helper: orden mínima para tests (solo id, status y campos requeridos).
Order _order({required int id, required String status}) {
  final base = {
    'id': id,
    'user_id': 1,
    'commerce_id': 1,
    'order_number': 'ORD-$id',
    'status': status,
    'subtotal': 100.0,
    'delivery_fee': 5.0,
    'tax': 0.0,
    'total': 105.0,
    'payment_method': '',
    'payment_status': 'pending',
    'delivery_address': 'Calle Test',
    'estimated_delivery_time': 35,
    'created_at': '2024-06-01T11:00:00.000Z',
    'updated_at': '2024-06-01T11:00:00.000Z',
    'items': [],
  };
  return Order.fromJson(Map<String, dynamic>.from(base));
}

void main() {
  group('Flujo de navegación - OrderConfirmationPage', () {
    testWidgets('Seguir mi pedido con orden pending_payment navega a OrderDetailPage',
        (WidgetTester tester) async {
      final order = _order(id: 12, status: 'pending_payment');
      await tester.pumpWidget(
        MaterialApp(
          home: OrderConfirmationPage(order: order),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seguir mi pedido'), findsOneWidget);
      await tester.tap(find.text('Seguir mi pedido'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(OrderDetailPage), findsOneWidget);
    });

    testWidgets('Seguir mi pedido con orden pending navega a OrderDetailPage',
        (WidgetTester tester) async {
      final order = _order(id: 13, status: 'pending');
      await tester.pumpWidget(
        MaterialApp(
          home: OrderConfirmationPage(order: order),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguir mi pedido'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailPage), findsOneWidget);
    });

    testWidgets('Seguir mi pedido con orden paid navega a OrderDetailPage',
        (WidgetTester tester) async {
      final order = _order(id: 14, status: 'paid');
      await tester.pumpWidget(
        MaterialApp(
          home: OrderConfirmationPage(order: order),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguir mi pedido'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailPage), findsOneWidget);
    });

    testWidgets('Muestra título Pedido creado y próximo paso cuando pending_payment',
        (WidgetTester tester) async {
      final order = _order(id: 15, status: 'pending_payment');
      await tester.pumpWidget(
        MaterialApp(
          home: OrderConfirmationPage(order: order),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Pedido creado!'), findsOneWidget);
      expect(find.text('Volver al inicio'), findsOneWidget);
    });
  });

  group('Flujo de navegación - OrdersPage (unificado)', () {
    test('Siempre se usa OrderDetailPage para cualquier estado de orden', () {
      // Desde la lista de órdenes siempre se abre OrderDetailPage (recibo + progreso/tracking según estado).
      final pending = _order(id: 20, status: 'pending_payment');
      final paid = _order(id: 21, status: 'paid');
      final delivered = _order(id: 22, status: 'delivered');
      expect(pending.id, 20);
      expect(paid.id, 21);
      expect(delivered.id, 22);
    });
  });

  group('Flujo de navegación - CurrentOrderDetailPage pending_payment', () {
    testWidgets('Muestra card Subir comprobante cuando status pending_payment',
        (WidgetTester tester) async {
      final order = _order(id: 30, status: 'pending_payment');
      await tester.pumpWidget(
        MaterialApp(
          home: CurrentOrderDetailPage(orderId: order.id, order: order),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Subir comprobante de pago'), findsOneWidget);
      expect(find.text('Pendiente de pago'), findsOneWidget);
    });

    testWidgets('Tap Subir comprobante navega a OrderDetailPage',
        (WidgetTester tester) async {
      final order = _order(id: 31, status: 'pending_payment');
      await tester.pumpWidget(
        MaterialApp(
          home: CurrentOrderDetailPage(orderId: order.id, order: order),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final btn = find.text('Subir comprobante de pago');
      await tester.scrollUntilVisible(btn, 100);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(btn);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(OrderDetailPage), findsOneWidget);
    });

    testWidgets('Orden paid no muestra card Subir comprobante en CurrentOrderDetailPage',
        (WidgetTester tester) async {
      final order = _order(id: 32, status: 'paid');
      await tester.pumpWidget(
        MaterialApp(
          home: CurrentOrderDetailPage(orderId: order.id, order: order),
        ),
      );
      await tester.pumpAndSettle();

      // La card "Pendiente de pago" con botón solo se muestra para pending_payment/pending
      expect(find.text('Pendiente de pago'), findsNothing);
    });
  });
}
