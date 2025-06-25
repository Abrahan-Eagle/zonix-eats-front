import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../lib/features/services/order_service.dart';
import '../../lib/models/cart_item.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  group('OrderService', () {
    late OrderService orderService;
    setUp(() {
      orderService = OrderService();
    });

    test('createOrder throws if cart is empty', () async {
      expect(() => orderService.createOrder([]), throwsException);
    });

    // Puedes agregar más tests según la lógica de OrderService
  });
}
