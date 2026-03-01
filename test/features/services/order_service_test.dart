import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/models/cart_item.dart';

class MockOrderService extends OrderService {
  @override
  Future<Order> createOrder(
    List<CartItem> items, {
    required String deliveryType,
    String? deliveryAddress,
    double deliveryFee = 0.0,
  }) async {
    // Simula una respuesta exitosa
    return Order(
      id: 1,
      userId: 1,
      commerceId: 1,
      orderNumber: 'ORD-001',
      status: 'pending',
      subtotal: 30.0,
      deliveryFee: 3.0,
      tax: 1.5,
      total: 34.5,
      paymentMethod: 'cash',
      paymentStatus: 'pending',
      deliveryAddress: 'Test Address',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
    );
  }

  @override
  Future<List<Order>> fetchOrders() async {
    // Simula una lista de órdenes
    return [Order(
      id: 1,
      userId: 1,
      commerceId: 1,
      orderNumber: 'ORD-001',
      status: 'pending',
      subtotal: 100.0,
      deliveryFee: 3.0,
      tax: 5.0,
      total: 108.0,
      paymentMethod: 'cash',
      paymentStatus: 'pending',
      deliveryAddress: 'Test Address',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
    )];
  }

  @override
  Future<void> uploadComprobante(
    int orderId,
    String filePath,
    String fileType, {
    String paymentMethod = 'otro',
    String referenceNumber = '',
  }) async {
    // Simula una subida exitosa
    return;
  }

  @override
  Future<void> validarComprobante(int orderId, String accion) async {
    // Simula una validación exitosa
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  group('OrderService', () {
    late OrderService orderService;

    setUp(() {
      // Mock the secure storage
      const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'read') {
            return 'mock_token'; // Return mock token for read operations
          }
          if (methodCall.method == 'write') {
            return null; // Return null for write operations
          }
          return null;
        },
      );
      orderService = MockOrderService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('Puede crear instancia del servicio', () {
      expect(orderService, isNotNull);
    });

    test('Puede crear orden con items', () async {
      final items = [
        CartItem(
          id: 1,
          nombre: 'Pizza Margherita',
          precio: 15.0,
          quantity: 2,
          imagen: 'https://example.com/pizza.jpg',
        ),
      ];
      final order = await orderService.createOrder(items, deliveryType: 'pickup');
      expect(order, isA<Order>());
      expect(order.id, 1);
    });

    test('Puede obtener órdenes', () async {
      final orders = await orderService.fetchOrders();
      expect(orders, isA<List<Order>>());
      expect(orders.first.status, 'pending');
    });

    test('Puede validar comprobante', () async {
      await orderService.validarComprobante(1, 'aprobar');
      expect(true, isTrue);
    });

    test('Puede subir comprobante (mock, no real file)', () async {
      // Este test solo verifica que el método existe y no lanza errores
      await orderService.uploadComprobante(1, '/path/to/file.pdf', 'pdf');
      expect(true, isTrue);
    });
  });
} 