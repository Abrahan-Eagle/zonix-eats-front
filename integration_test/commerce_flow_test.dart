import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flujo principal de comercio muestra datos reales', (WidgetTester tester) async {
    // Lanzar la app
    app.main();
    await tester.pumpAndSettle();

    // Aquí deberías simular el login como comercio, o navegar manualmente si ya está autenticado
    // Por simplicidad, asumimos que la app arranca en la pantalla de comercio

    // Simular login tocando el botón de Google
    final googleBtn = find.text('EMPEZAR CON GOOGLE');
    expect(googleBtn, findsOneWidget);
    await tester.tap(googleBtn);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Esperar a que cargue el dashboard
    expect(find.text('Dashboard Comercio'), findsOneWidget);

    // Ir a inventario
    final inventarioBtn = find.text('Ir a Inventario');
    await tester.tap(inventarioBtn);
    await tester.pumpAndSettle();
    expect(find.text('Inventario de Productos'), findsOneWidget);
    await tester.pumpAndSettle();
    // Esperar a que carguen productos reales
    expect(find.byType(ListTile), findsWidgets);

    // Ir a órdenes
    final ordenesBtn = find.text('Ver Órdenes');
    await tester.tap(ordenesBtn);
    await tester.pumpAndSettle();
    expect(find.text('Órdenes'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);

    // Ir a perfil
    final perfilBtn = find.text('Perfil de Comercio');
    await tester.tap(perfilBtn);
    await tester.pumpAndSettle();
    expect(find.text('Perfil de Comercio'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsWidgets);
  });
} 