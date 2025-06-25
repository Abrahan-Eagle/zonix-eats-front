import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../lib/features/services/cart_service.dart';
import '../../lib/models/cart_item.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  group('CartService', () {
    late CartService cartService;
    setUp(() {
      cartService = CartService();
    });

    test('addToCart adds an item', () {
      final item = CartItem(id: 1, nombre: 'Test', precio: 10.0, quantity: 1);
      cartService.addToCart(item);
      expect(cartService.items.length, 1);
    });

    test('removeFromCart removes an item', () {
      final item = CartItem(id: 1, nombre: 'Test', precio: 10.0, quantity: 1);
      cartService.addToCart(item);
      cartService.removeFromCart(item);
      expect(cartService.items.length, 0);
    });

    test('clearCart empties the cart', () {
      final item = CartItem(id: 1, nombre: 'Test', precio: 10.0, quantity: 1);
      cartService.addToCart(item);
      cartService.clearCart();
      expect(cartService.items.isEmpty, true);
    });
  });
}
