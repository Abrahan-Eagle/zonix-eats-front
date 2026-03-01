import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:zonix/features/screens/commerce/commerce_dashboard_page.dart';

void main() {
  testWidgets('Comercio ve dashboard y no ve acciones de cliente/delivery', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Dashboard Comercio'),
              ElevatedButton(onPressed: () {}, child: const Text('Ver órdenes')),
              ElevatedButton(onPressed: () {}, child: const Text('Ver productos')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Comercio'), findsOneWidget);
    expect(find.text('Ver órdenes'), findsOneWidget);
    expect(find.text('Ver productos'), findsOneWidget);
    // No debe haber acciones de cliente
    expect(find.text('Carrito'), findsNothing);
    // No debe haber acciones de delivery
    expect(find.text('Órdenes asignadas'), findsNothing);
  });
} 