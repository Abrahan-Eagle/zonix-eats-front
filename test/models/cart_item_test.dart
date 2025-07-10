import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/models/cart_item.dart';

void main() {
  group('CartItem', () {
    test('Crea item de carrito con datos básicos', () {
      final item = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 2,
        imagen: 'https://example.com/pizza.jpg',
      );

      expect(item.id, 1);
      expect(item.nombre, 'Pizza Margherita');
      expect(item.precio, 15.0);
      expect(item.quantity, 2);
      expect(item.imagen, 'https://example.com/pizza.jpg');
    });

    test('Crea item de carrito desde JSON', () {
      final json = {
        'id': 1,
        'nombre': 'Pizza Margherita',
        'precio': 15.0,
        'quantity': 2,
        'imagen': 'https://example.com/pizza.jpg',
      };

      final item = CartItem.fromJson(json);

      expect(item.id, 1);
      expect(item.nombre, 'Pizza Margherita');
      expect(item.precio, 15.0);
      expect(item.quantity, 2);
      expect(item.imagen, 'https://example.com/pizza.jpg');
    });

    test('Maneja precio como entero en JSON', () {
      final json = {
        'id': 1,
        'nombre': 'Pizza Margherita',
        'precio': 15,
        'quantity': 2,
        'imagen': 'https://example.com/pizza.jpg',
      };

      final item = CartItem.fromJson(json);

      expect(item.precio, 15.0);
    });

    test('Maneja precio como string en JSON', () {
      final json = {
        'id': 1,
        'nombre': 'Pizza Margherita',
        'precio': '15.50',
        'quantity': 2,
        'imagen': 'https://example.com/pizza.jpg',
      };

      final item = CartItem.fromJson(json);

      expect(item.precio, 15.50);
    });

    test('Compara items iguales', () {
      final item1 = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 2,
        imagen: 'https://example.com/pizza.jpg',
      );

      final item2 = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 2,
        imagen: 'https://example.com/pizza.jpg',
      );

      expect(item1, equals(item2));
    });

    test('Compara items diferentes', () {
      final item1 = CartItem(
        id: 1,
        nombre: 'Pizza Margherita',
        precio: 15.0,
        quantity: 2,
        imagen: 'https://example.com/pizza.jpg',
      );

      final item2 = CartItem(
        id: 2,
        nombre: 'Pizza Pepperoni',
        precio: 18.0,
        quantity: 1,
        imagen: 'https://example.com/pepperoni.jpg',
      );

      expect(item1, isNot(equals(item2)));
    });
  });
} 