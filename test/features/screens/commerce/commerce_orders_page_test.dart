import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../lib/features/screens/commerce/commerce_orders_page.dart';
import '../../../../lib/models/commerce_order.dart';
import '../../../../lib/services/commerce_order_service.dart';

class FakeOrderService extends CommerceOrderService {
  final Future<List<CommerceOrder>> Function()? fetchOrdersOverride;
  FakeOrderService({this.fetchOrdersOverride});
  @override
  Future<List<CommerceOrder>> fetchOrders() => fetchOrdersOverride?.call() ?? super.fetchOrders();
}

@GenerateMocks([CommerceOrderService])
void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  testWidgets('CommerceOrdersPage muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommerceOrdersPage()));
    expect(find.text('Órdenes de Comercio'), findsOneWidget);
  });

  testWidgets('Muestra loading al cargar órdenes', (WidgetTester tester) async {
    final service = FakeOrderService(fetchOrdersOverride: () async {
      await Future.delayed(const Duration(milliseconds: 500));
      return [];
    });
    await tester.pumpWidget(MaterialApp(home: CommerceOrdersPage(orderService: service)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600)); // Esperar a que termine el loading
  });

  testWidgets('Muestra error si falla la carga', (WidgetTester tester) async {
    final service = FakeOrderService(fetchOrdersOverride: () async => throw Exception('Fallo de red'));
    await tester.pumpWidget(MaterialApp(home: CommerceOrdersPage(orderService: service)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Error'), findsOneWidget);
  });

  testWidgets('Muestra lista de órdenes simulada', (WidgetTester tester) async {
    final now = DateTime.now();
    final orders = [
      CommerceOrder(id: 1, status: 'pendiente', total: 100, createdAt: now, updatedAt: now, items: [], customer: {}),
      CommerceOrder(id: 2, status: 'enviado', total: 200, createdAt: now, updatedAt: now, items: [], customer: {}),
    ];
    await tester.pumpWidget(MaterialApp(home: CommerceOrdersPage(initialOrders: orders)));
    await tester.pump();
    expect(find.text('Orden #1'), findsOneWidget);
    expect(find.text('Orden #2'), findsOneWidget);
    expect(find.text('Estado: pendiente'), findsOneWidget);
    expect(find.text('Estado: enviado'), findsOneWidget);
  });

  testWidgets('Muestra mensaje si no hay órdenes', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: CommerceOrdersPage(initialOrders: [])));
    await tester.pump();
    expect(find.text('No hay órdenes'), findsOneWidget);
  });
} 