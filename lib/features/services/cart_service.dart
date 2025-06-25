import 'dart:collection';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../helpers/auth_helper.dart';

class CartService extends ChangeNotifier {
  final List<Map<String, dynamic>> _cart = [];
  String get _baseUrl => dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000/api';

  UnmodifiableListView<Map<String, dynamic>> get items => UnmodifiableListView(_cart);

  void addToCart(Map<String, dynamic> product) {
    _cart.add(product);
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> product) {
    _cart.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> addToRemoteCart(Map<String, dynamic> product) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/cart/add');
    final response = await http.post(
      url,
      body: jsonEncode({'product_id': product['id'], 'quantity': 1}),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar producto al carrito remoto');
    }
  }

  Future<List<dynamic>> fetchRemoteCart() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/cart');
    final response = await http.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el carrito remoto');
    }
  }
}
