import 'dart:collection';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../helpers/auth_helper.dart';
import '../../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _cart = [];
  String get _baseUrl => dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000/api';

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_cart);

  void addToCart(CartItem product) {
    _cart.add(product);
    notifyListeners();
  }

  void removeFromCart(CartItem product) {
    _cart.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void decrementQuantity(CartItem product) {
    final index = _cart.indexWhere((item) => item.id == product.id);
    if (index != -1) {
      final current = _cart[index];
      if (current.quantity > 1) {
        _cart[index] = CartItem(
          id: current.id,
          nombre: current.nombre,
          precio: current.precio,
          quantity: current.quantity - 1,
        );
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  Future<void> addToRemoteCart(CartItem product) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/cart/add');
    final response = await http.post(
      url,
      body: jsonEncode({'product_id': product.id, 'quantity': product.quantity}),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar producto al carrito remoto');
    }
  }

  Future<List<CartItem>> fetchRemoteCart() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/cart');
    final response = await http.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map<CartItem>((item) => CartItem.fromJson(item)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Error al obtener el carrito remoto');
    }
  }
}
