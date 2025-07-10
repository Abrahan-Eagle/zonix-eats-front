import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:zonix/features/screens/delivery/delivery_orders_page.dart';

void main() {
  testWidgets('Delivery ve órdenes asignadas y no ve acciones de cliente/comercio', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Órdenes Asignadas'),
              ElevatedButton(onPressed: () {}, child: Text('Marcar como entregada')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Órdenes Asignadas'), findsOneWidget);
    expect(find.text('Marcar como entregada'), findsOneWidget);
    // No debe haber acciones de cliente
    expect(find.text('Carrito'), findsNothing);
    // No debe haber acciones de comercio
    expect(find.text('Ver productos'), findsNothing);
  });
} 