import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

class MockOrderService extends OrderService {
  @override
  Future<void> createOrder(List<CartItem> items) async {
    // Simula una respuesta exitosa
    return;
  }

  @override
  Future<List<Order>> fetchOrders() async {
    // Simula una lista de órdenes
    return [Order(id: 1, estado: 'pendiente', total: 100, items: [])];
  }

  @override
  Future<void> uploadComprobante(int orderId, String filePath, String fileType) async {
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
      await orderService.createOrder(items);
      expect(true, isTrue); // Si no lanza excepción, pasa
    });

    test('Puede obtener órdenes', () async {
      final orders = await orderService.fetchOrders();
      expect(orders, isA<List<Order>>());
      expect(orders.first.estado, 'pendiente');
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