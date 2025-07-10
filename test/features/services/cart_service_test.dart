import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/models/cart_item.dart';

void main() {
  group('CartService', () {
    late CartService cartService;

    setUp(() {
      cartService = CartService();
    });

    test('Inicializa con carrito vacío', () {
      expect(cartService.items.length, 0);
    });

    test('Agrega item al carrito', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 1,
        imagen: 'https://example.com/pizza.jpg',
      );

      cartService.addToCart(item);

      expect(cartService.items.length, 1);
      expect(cartService.items.first.nombre, 'Pizza Margherita');
    });

    test('Elimina item del carrito', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 1,
        imagen: 'https://example.com/pizza.jpg',
      );

      cartService.addToCart(item);
      cartService.removeFromCart(item);

      expect(cartService.items.length, 0);
    });

    test('Limpia el carrito', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 1,
        imagen: 'https://example.com/pizza.jpg',
      );

      cartService.addToCart(item);
      cartService.clearCart();

      expect(cartService.items.length, 0);
    });

    test('Decrementa cantidad de item', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 2,
        imagen: 'https://example.com/pizza.jpg',
      );

      cartService.addToCart(item);
      cartService.decrementQuantity(item);

      expect(cartService.items.first.quantity, 1);
    });

    test('Elimina item cuando cantidad llega a 0', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 1,
        imagen: 'https://example.com/pizza.jpg',
      );

      cartService.addToCart(item);
      cartService.decrementQuantity(item);

      expect(cartService.items.length, 0);
    });
  });
} 