import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../lib/features/screens/commerce/commerce_dashboard_page.dart';
import '../../../../lib/models/commerce_profile.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  testWidgets('CommerceDashboardPage muestra accesos rápidos (botones)', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(
      home: CommerceDashboardPage(initialProfile: profile, initialUnreadNotifications: 0),
    ));
    expect(find.text('Ir a Inventario'), findsOneWidget);
    expect(find.text('Ver Órdenes'), findsOneWidget);
    expect(find.text('Perfil de Comercio'), findsOneWidget);
  });

  testWidgets('Muestra estado abierto/cerrado del comercio (inyectado)', (WidgetTester tester) async {
    final abierto = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    final cerrado = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: false);
    await tester.pumpWidget(MaterialApp(home: CommerceDashboardPage(initialProfile: abierto, initialUnreadNotifications: 0)));
    await tester.pump();
    expect(find.text('Comercio ABIERTO'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: CommerceDashboardPage(initialProfile: cerrado, initialUnreadNotifications: 0)));
    await tester.pump();
    expect(find.text('Comercio CERRADO'), findsOneWidget);
  });

  testWidgets('Muestra badge de notificaciones si hay no leídas (inyectado)', (WidgetTester tester) async {
    final abierto = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceDashboardPage(initialProfile: abierto, initialUnreadNotifications: 5)));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });
} 