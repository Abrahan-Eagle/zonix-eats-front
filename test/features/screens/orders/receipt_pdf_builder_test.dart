import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/screens/orders/receipt_pdf_builder.dart';
import 'package:zonix/models/order.dart';

/// Regresión: matriz del plan (pocos ítems vs muchas filas / multipágina) sin crash ni PDF vacío.
void main() {
  group('ReceiptPdfBuilder.build', () {
    test('escenario 1: pocos productos — genera PDF con bytes', () async {
      final order = _fakeOrder(itemCount: 3);
      final bytes = await ReceiptPdfBuilder.build(order);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(800));
    });

    test('escenario 2–3: muchas filas — multipágina sin excepción', () async {
      final order = _fakeOrder(
        itemCount: 24,
        productNamePrefix:
            'Producto de prueba con texto largo para ocupar altura en tabla ',
      );
      final bytes = await ReceiptPdfBuilder.build(order);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(800));
    });

    test('notas especiales + envío > 0 — no falla', () async {
      final order = _fakeOrder(itemCount: 5).copyWith(
        specialInstructions: 'Sin cebolla, extra salsa',
        deliveryFee: 3.5,
        total: 5 * 10.0 + 3.5,
      );
      final bytes = await ReceiptPdfBuilder.build(order);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(800));
    });
  });
}

Order _fakeOrder({
  required int itemCount,
  String productNamePrefix = 'Producto ',
}) {
  final items = List<OrderItem>.generate(
    itemCount,
    (i) => OrderItem(
      id: i + 1,
      orderId: 1,
      productId: i + 1,
      productName: '$productNamePrefix$i',
      productImage: '',
      price: 10.0,
      quantity: 1,
      total: 10.0,
    ),
  );
  final subtotal = itemCount * 10.0;
  return Order(
    id: 999,
    userId: 1,
    commerceId: 1,
    orderNumber: 'TEST-999',
    status: 'delivered',
    subtotal: subtotal,
    deliveryFee: 2.0,
    tax: 0,
    total: subtotal + 2.0,
    paymentMethod: 'pago_movil',
    paymentStatus: 'paid',
    deliveryAddress: 'Av. Principal 1, Valencia',
    createdAt: DateTime.utc(2026, 4, 1, 12),
    updatedAt: DateTime.utc(2026, 4, 1, 12),
    items: items,
    commerce: const {
      'address': 'Av. Principal El Socorro, Valencia',
      'business_name': 'Comercio prueba PDF',
    },
    deliveryType: 'delivery',
    referenceNumber: '123456',
  );
}
