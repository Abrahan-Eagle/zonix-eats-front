import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/screens/orders/buyer_disputes_page.dart';
import 'package:zonix/features/services/dispute_service.dart';

class _FakeDisputeService extends DisputeService {
  @override
  Future<Map<String, dynamic>> getBuyerDisputes({int page = 1, int perPage = 15}) async {
    return {
      'items': [
        {
          'id': 1,
          'order_id': 101,
          'type': 'delivery_problem',
          'status': 'pending',
          'description': 'No llegó completo',
          'resolved_at': null,
        },
        {
          'id': 2,
          'order_id': 202,
          'type': 'payment_issue',
          'status': 'resolved',
          'description': 'Cobro duplicado',
          'resolved_at': DateTime.now().toIso8601String(),
        },
      ],
      'pagination': {'current_page': 1, 'last_page': 1, 'total': 2},
    };
  }
}

void main() {
  testWidgets('BuyerDisputesPage filtra por estado y muestra badge de resolucion reciente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BuyerDisputesPage(service: _FakeDisputeService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Orden #101 · Problema de entrega'), findsOneWidget);
    expect(find.text('Orden #202 · Problema de pago'), findsOneWidget);
    expect(find.text('Resuelta hoy'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendiente').last);
    await tester.pumpAndSettle();

    expect(find.text('Orden #101 · Problema de entrega'), findsOneWidget);
    expect(find.text('Orden #202 · Problema de pago'), findsNothing);
  });
}
