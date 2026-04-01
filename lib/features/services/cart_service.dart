import 'dart:collection';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../models/cart_item.dart';
import '../../config/app_config.dart';

enum CartAddStatus {
  added,
  updatedQuantity,
  replacedCommerce,
  blockedLimit,
  blockedStock,
}

class CartAddResult {
  final CartAddStatus status;

  const CartAddResult(this.status);

  bool get replacedCommerce => status == CartAddStatus.replacedCommerce;
  bool get blocked =>
      status == CartAddStatus.blockedLimit || status == CartAddStatus.blockedStock;
}

class CartService extends ChangeNotifier {
  final List<CartItem> _cart = [];

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_cart);

  // Métodos locales del carrito
  /// Agrega un producto al carrito. Si el carrito tiene productos de otro comercio,
  /// los reemplaza automáticamente (regla: solo un comercio por carrito).
  CartAddResult addToCart(CartItem product) {
    final newCommerceId = product.commerceId;
    if (_cart.isNotEmpty) {
      final existingCommerceId = _cart.first.commerceId;
      if (existingCommerceId != newCommerceId) {
        _cart.clear();
        _cart.add(product);
        notifyListeners();
        return const CartAddResult(CartAddStatus.replacedCommerce);
      }
    }
    final existingIndex =
        _cart.indexWhere((item) => item.lineKey == product.lineKey);
    if (existingIndex != -1) {
      final current = _cart[existingIndex];
      final nextQuantity = current.quantity + product.quantity;
      if (nextQuantity > 100) {
        return const CartAddResult(CartAddStatus.blockedLimit);
      }
      if (current.stock != null && nextQuantity > current.stock!) {
        return const CartAddResult(CartAddStatus.blockedStock);
      }
      _cart[existingIndex] = CartItem(
        id: current.id,
        nombre: current.nombre,
        precio: current.precio,
        quantity: nextQuantity,
        imagen: current.imagen,
        image: current.image,
        stock: current.stock,
        category: current.category,
        notes: current.notes,
        commerceId: current.commerceId,
        lineId: current.lineId,
      );
      notifyListeners();
      return const CartAddResult(CartAddStatus.updatedQuantity);
    } else {
      _cart.add(product);
      notifyListeners();
      return const CartAddResult(CartAddStatus.added);
    }
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
    final index = _cart.indexWhere((item) => item.lineKey == product.lineKey);
    if (index != -1) {
      final current = _cart[index];
      if (current.quantity > 1) {
        _cart[index] = CartItem(
          id: current.id,
          nombre: current.nombre,
          precio: current.precio,
          quantity: current.quantity - 1,
          imagen: current.imagen,
          image: current.image,
          stock: current.stock,
          category: current.category,
          notes: current.notes,
          commerceId: current.commerceId,
          lineId: current.lineId,
        );
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void incrementQuantity(CartItem product) {
    final index = _cart.indexWhere((item) => item.lineKey == product.lineKey);
    if (index != -1) {
      final current = _cart[index];
      final nextQuantity = current.quantity + 1;
      if (nextQuantity > 100) return;
      if (current.stock != null && nextQuantity > current.stock!) return;
      _cart[index] = CartItem(
        id: current.id,
        nombre: current.nombre,
        precio: current.precio,
        quantity: nextQuantity,
        imagen: current.imagen,
        image: current.image,
        stock: current.stock,
        category: current.category,
        notes: current.notes,
        commerceId: current.commerceId,
        lineId: current.lineId,
      );
      notifyListeners();
    }
  }

  // Métodos para conectar con el backend

  // POST /api/buyer/cart/add
  Future<void> addToRemoteCart(CartItem product) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/cart/add');
    final response = await http.post(
      url,
      body:
          jsonEncode({
            'product_id': product.id,
            'quantity': product.quantity,
            if (product.notes != null && product.notes!.trim().isNotEmpty)
              'notes': product.notes,
            'line_id': product.lineKey,
          }),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        // Sincronizar con el carrito local
        addToCart(product);
      } else {
        throw Exception(
            data['message'] ?? 'Error al agregar producto al carrito');
      }
    } else {
      throw Exception(
          'Error al agregar producto al carrito remoto: ${response.statusCode}');
    }
  }

  // GET /api/buyer/cart
  Future<List<CartItem>> fetchRemoteCart() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/cart');
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = _parseCartItems(data);
      _cart
        ..clear()
        ..addAll(items);
      notifyListeners();
      return items;
    } else {
      throw Exception(
          'Error al obtener el carrito remoto: ${response.statusCode}');
    }
  }

  // PUT /api/buyer/cart/update-quantity
  Future<void> updateQuantity(int productId, int quantity, {String? lineId}) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/cart/update-quantity');
    final response = await http.put(
      url,
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
        if (lineId != null && lineId.trim().isNotEmpty) 'line_id': lineId,
      }),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Actualizar carrito local
        final index = _cart.indexWhere((item) =>
            lineId != null && lineId.trim().isNotEmpty
                ? item.lineKey == lineId
                : item.id == productId);
        if (index != -1) {
          if (quantity > 0) {
            final current = _cart[index];
            _cart[index] = CartItem(
              id: current.id,
              nombre: current.nombre,
              precio: current.precio,
              quantity: quantity,
              imagen: current.imagen,
              image: current.image,
              stock: current.stock,
              category: current.category,
              notes: current.notes,
              commerceId: current.commerceId,
              lineId: current.lineId,
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
  Future<void> removeFromRemoteCart(int productId, {String? lineId}) async {
    final headers = await AuthHelper.getAuthHeaders();
    final baseUrl = '${AppConfig.apiUrl}/api/buyer/cart/$productId';
    final url = (lineId != null && lineId.trim().isNotEmpty)
        ? Uri.parse('$baseUrl?line_id=${Uri.encodeQueryComponent(lineId)}')
        : Uri.parse(baseUrl);
    final response = await http.delete(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        // Remover del carrito local
        _cart.removeWhere((item) =>
            lineId != null && lineId.trim().isNotEmpty
                ? item.lineKey == lineId
                : item.id == productId);
        notifyListeners();
      } else {
        throw Exception(
            data['message'] ?? 'Error al eliminar producto del carrito');
      }
    } else {
      throw Exception(
          'Error al eliminar producto del carrito: ${response.statusCode}');
    }
  }

  // POST /api/buyer/cart/notes
  Future<void> addNotes(String notes) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/cart/notes');
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
      debugPrint('Error sincronizando carrito: $e');
    }
  }

  // Método para limpiar carrito remoto
  Future<void> clearRemoteCart() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/cart');
    final response = await http.delete(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        // Limpiar carrito local
        clearCart();
      } else {
        throw Exception(data['message'] ?? 'Error al limpiar carrito');
      }
    } else {
      throw Exception('Error al limpiar carrito: ${response.statusCode}');
    }
  }

  // Métodos de conveniencia para compatibilidad
  Future<List<CartItem>> getCart() async {
    try {
      return await fetchRemoteCart();
    } catch (e) {
      // Si falla, devolver carrito local
      return List.from(_cart);
    }
  }

  Future<void> removeFromCartById(int productId, {String? lineId}) async {
    await removeFromRemoteCart(productId, lineId: lineId);
  }

  List<CartItem> _parseCartItems(dynamic payload) {
    dynamic data = payload;
    if (payload is Map<String, dynamic>) {
      if (payload['success'] == true && payload['data'] != null) {
        data = payload['data'];
      } else if (payload['cart'] != null) {
        data = payload['cart'];
      }
    }

    dynamic itemsData = data;
    if (data is Map<String, dynamic> && data['items'] is List) {
      itemsData = data['items'];
    }

    if (itemsData is! List) return <CartItem>[];

    return itemsData.map<CartItem>((item) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey('id')) {
          return CartItem.fromJson(item);
        }
        // Compatibilidad legacy: item mínimo con product_id y quantity
        return CartItem(
          id: item['product_id'] ?? 0,
          nombre: item['nombre'] ?? 'Producto',
          precio: (item['precio'] is num)
              ? (item['precio'] as num).toDouble()
              : 0.0,
          quantity: item['quantity'] ?? 1,
          imagen: item['image'] ?? item['imagen'],
          image: item['image'] ?? item['imagen'],
          stock: item['stock'] ?? item['stock_quantity'],
          category: item['category'],
          commerceId: item['commerce_id'],
          lineId: item['line_id']?.toString(),
        );
      }
      return CartItem(id: 0, nombre: 'Producto', precio: 0.0, quantity: 1);
    }).toList();
  }
}
