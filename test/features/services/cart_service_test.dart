import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/models/cart_item.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

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

    test('Reemplaza carrito al agregar producto de otro comercio (uni-commerce)', () {
      final item1 = CartItem(id: 1, nombre: 'Pizza A', precio: 10.0, quantity: 1, imagen: 'a.jpg', commerceId: 1);
      final item2 = CartItem(id: 2, nombre: 'Pizza B', precio: 12.0, quantity: 1, imagen: 'b.jpg', commerceId: 1);
      final item3 = CartItem(id: 3, nombre: 'Hamburguesa', precio: 8.0, quantity: 1, imagen: 'c.jpg', commerceId: 2);

      cartService.addToCart(item1);
      cartService.addToCart(item2);
      expect(cartService.items.length, 2);

      final result = cartService.addToCart(item3);
      expect(result.status, CartAddStatus.replacedCommerce);
      expect(cartService.items.length, 1);
      expect(cartService.items.first.id, 3);
      expect(cartService.items.first.nombre, 'Hamburguesa');
    });

    test('No reemplaza al agregar producto del mismo comercio', () {
      final item1 = CartItem(id: 1, nombre: 'Pizza A', precio: 10.0, quantity: 1, imagen: 'a.jpg', commerceId: 1);
      final item2 = CartItem(id: 2, nombre: 'Pizza B', precio: 12.0, quantity: 1, imagen: 'b.jpg', commerceId: 1);

      cartService.addToCart(item1);
      final result = cartService.addToCart(item2);
      expect(result.status, CartAddStatus.added);
      expect(cartService.items.length, 2);
    });

    test('No incrementa cuando supera stock local', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza A',
        precio: 10.0,
        quantity: 1,
        imagen: 'a.jpg',
        stock: 1,
        commerceId: 1,
      );

      cartService.addToCart(item);
      cartService.incrementQuantity(item);

      expect(cartService.items.first.quantity, 1);
    });

    test('Bloquea agregar cuando supera limite de 100 unidades', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza A',
        precio: 10.0,
        quantity: 100,
        imagen: 'a.jpg',
        commerceId: 1,
      );

      cartService.addToCart(item);
      final result = cartService.addToCart(
        CartItem(
          id: 1,
          nombre: 'Pizza A',
          precio: 10.0,
          quantity: 1,
          imagen: 'a.jpg',
          commerceId: 1,
        ),
      );

      expect(result.status, CartAddStatus.blockedLimit);
      expect(cartService.items.first.quantity, 100);
    });

    test('No fusiona personalizaciones distintas del mismo producto', () {
      final base = CartItem(
        id: 1,
        nombre: 'Pizza A',
        precio: 10.0,
        quantity: 1,
        imagen: 'a.jpg',
        commerceId: 1,
        notes: 'Extras: queso',
      );
      final variante = CartItem(
        id: 1,
        nombre: 'Pizza A',
        precio: 10.0,
        quantity: 1,
        imagen: 'a.jpg',
        commerceId: 1,
        notes: 'Extras: tocineta',
      );

      cartService.addToCart(base);
      cartService.addToCart(variante);

      expect(cartService.items.length, 2);
    });
  });
} 