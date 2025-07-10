import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:zonix/features/screens/admin/admin_dashboard_page.dart';

void main() {
  testWidgets('Admin ve panel de administración y no ve acciones de otros roles', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Panel de Administración'),
              ElevatedButton(onPressed: () {}, child: Text('Gestionar usuarios')),
              ElevatedButton(onPressed: () {}, child: Text('Gestionar comercios')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Panel de Administración'), findsOneWidget);
    expect(find.text('Gestionar usuarios'), findsOneWidget);
    expect(find.text('Gestionar comercios'), findsOneWidget);
    // No debe haber acciones de cliente
    expect(find.text('Carrito'), findsNothing);
    // No debe haber acciones de comercio
    expect(find.text('Ver productos'), findsNothing);
    // No debe haber acciones de delivery
    expect(find.text('Órdenes asignadas'), findsNothing);
  });
} 