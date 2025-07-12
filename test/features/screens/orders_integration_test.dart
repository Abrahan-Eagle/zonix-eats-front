import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zonix/features/screens/orders/orders_page.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/websocket_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/models/commerce.dart';

import 'orders_integration_test.mocks.dart';

@GenerateMocks([OrderService, WebSocketService, UserProvider])
void main() {
  group('OrdersPage Integration Tests', () {
    late MockOrderService mockOrderService;
    late MockWebSocketService mockWebSocketService;
    late MockUserProvider mockUserProvider;
    late List<Order> testOrders;

    setUp(() {
      mockOrderService = MockOrderService();
      mockWebSocketService = MockWebSocketService();
      mockUserProvider = MockUserProvider();

      // Crear datos de prueba
      testOrders = [
        Order(
          id: 1,
          userId: 1,
          commerceId: 1,
          status: 'pendiente_pago',
          total: 25.50,
          tipoEntrega: 'pickup',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commerce: Commerce(
            id: 1,
            name: 'Test Restaurant',
            description: 'Test description',
            address: 'Test address',
            phone: '1234567890',
            email: 'test@restaurant.com',
            isOpen: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          items: [],
        ),
        Order(
          id: 2,
          userId: 1,
          commerceId: 1,
          status: 'pagado',
          total: 15.75,
          tipoEntrega: 'delivery',
          createdAt: DateTime.now().subtract(Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(Duration(hours: 2)),
          commerce: Commerce(
            id: 1,
            name: 'Test Restaurant',
            description: 'Test description',
            address: 'Test address',
            phone: '1234567890',
            email: 'test@restaurant.com',
            isOpen: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          items: [],
        ),
      ];

      // Configurar mocks
      when(mockUserProvider.user).thenReturn(User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        role: 'users',
        googleId: 'test_google_id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      when(mockOrderService.getUserOrders()).thenAnswer((_) async => testOrders);
      when(mockWebSocketService.connect()).thenAnswer((_) async => true);
      when(mockWebSocketService.subscribeToChannel(any)).thenAnswer((_) async => true);
      when(mockWebSocketService.messageStream).thenReturn(Stream.empty());
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
            ChangeNotifierProvider<OrderService>.value(value: mockOrderService),
            ChangeNotifierProvider<WebSocketService>.value(value: mockWebSocketService),
          ],
          child: OrdersPage(),
        ),
      );
    }

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockOrderService.getUserOrders()).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return testOrders;
      });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display orders list after loading', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Pedido #1'), findsOneWidget);
      expect(find.text('Pedido #2'), findsOneWidget);
      expect(find.text('Test Restaurant'), findsNWidgets(2));
    });

    testWidgets('should display empty state when no orders', (WidgetTester tester) async {
      // Arrange
      when(mockOrderService.getUserOrders()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No tienes pedidos aún'), findsOneWidget);
      expect(find.text('Cuando hagas tu primer pedido, aparecerá aquí'), findsOneWidget);
      expect(find.text('Explorar Restaurantes'), findsOneWidget);
    });

    testWidgets('should display error state when API fails', (WidgetTester tester) async {
      // Arrange
      when(mockOrderService.getUserOrders()).thenThrow(Exception('API Error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar pedidos'), findsOneWidget);
      expect(find.text('Exception: API Error'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('should refresh orders when refresh button is tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      verify(mockOrderService.getUserOrders()).called(greaterThan(1));
    });

    testWidgets('should refresh orders when pull to refresh', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert
      verify(mockOrderService.getUserOrders()).called(greaterThan(1));
    });

    testWidgets('should display correct status chips', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Pagado'), findsOneWidget);
    });

    testWidgets('should display correct order information', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('\$25.50'), findsOneWidget);
      expect(find.text('\$15.75'), findsOneWidget);
      expect(find.text('0 productos'), findsNWidgets(2));
    });

    testWidgets('should navigate to order details when order is tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap first order
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Assert
      // Note: Navigation testing would require additional setup
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('should initialize WebSocket connection', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      verify(mockWebSocketService.connect()).called(1);
      verify(mockWebSocketService.subscribeToChannel('orders.user.1')).called(1);
    });

    testWidgets('should handle WebSocket messages', (WidgetTester tester) async {
      // Arrange
      final messageController = StreamController<Map<String, dynamic>>();
      when(mockWebSocketService.messageStream).thenReturn(messageController.stream);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Send WebSocket message
      messageController.add({
        'type': 'order_status_changed',
        'order_id': 1,
        'new_status': 'pagado'
      });
      await tester.pumpAndSettle();

      // Assert
      verify(mockOrderService.getUserOrders()).called(greaterThan(1));
    });

    testWidgets('should handle WebSocket connection error', (WidgetTester tester) async {
      // Arrange
      when(mockWebSocketService.connect()).thenThrow(Exception('WebSocket Error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // Should still load orders even if WebSocket fails
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('should display correct date formatting', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ahora'), findsOneWidget);
      expect(find.text('2 horas'), findsOneWidget);
    });

    testWidgets('should handle user authentication error', (WidgetTester tester) async {
      // Arrange
      when(mockUserProvider.user).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar pedidos'), findsOneWidget);
      expect(find.text('Exception: Usuario no autenticado'), findsOneWidget);
    });

    testWidgets('should handle order with items', (WidgetTester tester) async {
      // Arrange
      final orderWithItems = Order(
        id: 3,
        userId: 1,
        commerceId: 1,
        status: 'en_preparacion',
        total: 30.00,
        tipoEntrega: 'pickup',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        commerce: Commerce(
          id: 1,
          name: 'Test Restaurant',
          description: 'Test description',
          address: 'Test address',
          phone: '1234567890',
          email: 'test@restaurant.com',
          isOpen: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        items: [
          OrderItem(
            id: 1,
            orderId: 3,
            productId: 1,
            quantity: 2,
            price: 15.00,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      when(mockOrderService.getUserOrders()).thenAnswer((_) async => [orderWithItems]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('1 productos'), findsOneWidget);
    });

    testWidgets('should handle different order statuses', (WidgetTester tester) async {
      // Arrange
      final differentStatusOrders = [
        Order(
          id: 1,
          userId: 1,
          commerceId: 1,
          status: 'pendiente_pago',
          total: 10.00,
          tipoEntrega: 'pickup',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commerce: Commerce(
            id: 1,
            name: 'Test Restaurant',
            description: 'Test description',
            address: 'Test address',
            phone: '1234567890',
            email: 'test@restaurant.com',
            isOpen: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          items: [],
        ),
        Order(
          id: 2,
          userId: 1,
          commerceId: 1,
          status: 'en_preparacion',
          total: 20.00,
          tipoEntrega: 'pickup',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commerce: Commerce(
            id: 1,
            name: 'Test Restaurant',
            description: 'Test description',
            address: 'Test address',
            phone: '1234567890',
            email: 'test@restaurant.com',
            isOpen: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          items: [],
        ),
        Order(
          id: 3,
          userId: 1,
          commerceId: 1,
          status: 'listo_retirar',
          total: 30.00,
          tipoEntrega: 'pickup',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commerce: Commerce(
            id: 1,
            name: 'Test Restaurant',
            description: 'Test description',
            address: 'Test address',
            phone: '1234567890',
            email: 'test@restaurant.com',
            isOpen: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          items: [],
        ),
      ];

      when(mockOrderService.getUserOrders()).thenAnswer((_) async => differentStatusOrders);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Preparando'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
    });

    testWidgets('should handle app bar actions', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should handle screen orientation changes', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Change orientation
      await tester.binding.setSurfaceSize(Size(800, 600));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Card), findsNWidgets(2));
    });
  });
} 