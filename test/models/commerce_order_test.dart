import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/models/commerce_order.dart';

void main() {
  test('CommerceOrder normaliza alias legacy a estado canónico', () {
    final order = CommerceOrder.fromJson({
      'id': 1,
      'profile_id': 1,
      'commerce_id': 1,
      'delivery_type': 'delivery',
      'status': 'on_way',
      'total': 25.0,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    });

    expect(order.status, 'shipped');
    expect(order.isOnWay, true);
    expect(order.statusText, 'En camino');
  });

  test('CommerceOrder shipped pickup muestra listo para recoger', () {
    final order = CommerceOrder.fromJson({
      'id': 2,
      'profile_id': 1,
      'commerce_id': 1,
      'delivery_type': 'pickup',
      'status': 'shipped',
      'total': 25.0,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    });

    expect(order.statusText, 'Listo para recoger');
  });
}
