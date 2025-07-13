import 'dart:collection';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../helpers/auth_helper.dart';
import '../../models/cart_item.dart';
import '../../config/app_config.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _cart = [];

  final String _baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? (dotenv.env['API_URL_PROD'] ?? 'https://zonix.uniblockweb.com')
      : (dotenv.env['API_URL_LOCAL'] ?? 'http://192.168.0.101:8000');

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_cart);

  // Métodos locales del carrito
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

  // Métodos para conectar con el backend

  // POST /api/buyer/cart/add
  Future<void> addToRemoteCart(CartItem product) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/cart/add');
    final response = await http.post(
      url,
      body: jsonEncode({
        'product_id': product.id, 
        'quantity': product.quantity
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Sincronizar con el carrito local
        addToCart(product);
      } else {
        throw Exception(data['message'] ?? 'Error al agregar producto al carrito');
      }
    } else {
      throw Exception('Error al agregar producto al carrito remoto: ${response.statusCode}');
    }
  }

  // GET /api/buyer/cart
  Future<List<CartItem>> fetchRemoteCart() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/cart');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle the new API response structure with success and data wrapper
      if (data['success'] == true && data['data'] != null) {
        final cartData = data['data'];
        if (cartData is List) {
          final items = cartData.map<CartItem>((item) => CartItem.fromJson(item)).toList();
          // Sincronizar con el carrito local
          _cart.clear();
          _cart.addAll(items);
          notifyListeners();
          return items;
        }
      }
      return [];
    } else {
      throw Exception('Error al obtener el carrito remoto: ${response.statusCode}');
    }
  }

  // PUT /api/buyer/cart/update-quantity
  Future<void> updateQuantity(int productId, int quantity) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/cart/update-quantity');
    final response = await http.put(
      url,
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Actualizar carrito local
        final index = _cart.indexWhere((item) => item.id == productId);
        if (index != -1) {
          if (quantity > 0) {
            _cart[index] = CartItem(
              id: _cart[index].id,
              nombre: _cart[index].nombre,
              precio: _cart[index].precio,
              quantity: quantity,
            );
          } else {
            _cart.removeAt(index);
          }
          notifyListeners();
        }
      } else {
        throw Exception(data['message'] ?? 'Error al actualizar cantidad');
      }
    } else {
      throw Exception('Error al actualizar cantidad: ${response.statusCode}');
    }
  }

  // DELETE /api/buyer/cart/{productId}
  Future<void> removeFromRemoteCart(int productId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/cart/$productId');
    final response = await http.delete(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Remover del carrito local
        _cart.removeWhere((item) => item.id == productId);
        notifyListeners();
      } else {
        throw Exception(data['message'] ?? 'Error al eliminar producto del carrito');
      }
    } else {
      throw Exception('Error al eliminar producto del carrito: ${response.statusCode}');
    }
  }

  // POST /api/buyer/cart/notes
  Future<void> addNotes(String notes) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/cart/notes');
    final response = await http.post(
      url,
      body: jsonEncode({'notes': notes}),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Las notas se guardan en el backend
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al agregar notas');
      }
    } else {
      throw Exception('Error al agregar notas: ${response.statusCode}');
    }
  }

  // Método para sincronizar carrito local con remoto
  Future<void> syncCart() async {
    try {
      await fetchRemoteCart();
    } catch (e) {
      // Si falla la sincronización, mantener el carrito local
      print('Error sincronizando carrito: $e');
    }
  }

  // Método para limpiar carrito remoto
  Future<void> clearRemoteCart() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/cart');
    final response = await http.delete(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Limpiar carrito local
        clearCart();
      } else {
        throw Exception(data['message'] ?? 'Error al limpiar carrito');
      }
    } else {
      throw Exception('Error al limpiar carrito: ${response.statusCode}');
    }
  }
}
