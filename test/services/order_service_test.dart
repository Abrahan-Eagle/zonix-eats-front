import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/cart_item.dart';

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
      
      orderService = OrderService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('createOrder throws if cart is empty', () async {
      expect(
        () => orderService.createOrder([], deliveryType: 'pickup'),
        throwsException,
      );
    });

    // Puedes agregar más tests según la lógica de OrderService
  });
}
