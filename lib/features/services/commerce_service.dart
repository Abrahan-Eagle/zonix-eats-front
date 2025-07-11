import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:zonix/models/commerce.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/models/order.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommerceService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
  
  // Mock data for development (will be replaced with real API calls)
  static final List<Commerce> _mockCommerces = [
    Commerce(
      id: 1,
      name: 'Pizza Express',
      description: 'Las mejores pizzas de la ciudad',
      address: 'Av. Principal 123, Lima',
      phone: '+51 123 456 789',
      email: 'info@pizzaexpress.com',
      logo: 'https://via.placeholder.com/150',
      isActive: true,
      category: 'Restaurante',
      rating: 4.5,
      reviewCount: 156,
      openingHours: '10:00 - 22:00',
      deliveryFee: 5.0,
      deliveryTime: 30,
      minimumOrder: 15.0,
      paymentMethods: ['Efectivo', 'Tarjeta', 'Transferencia'],
      cuisines: ['Pizza', 'Italiana', 'Pasta'],
      location: {'lat': -12.0464, 'lng': -77.0428},
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Commerce(
      id: 2,
      name: 'Sushi Master',
      description: 'Sushi fresco y delicioso',
      address: 'Jr. Sushi 456, Lima',
      phone: '+51 987 654 321',
      email: 'contact@sushimaster.com',
      logo: 'https://via.placeholder.com/150',
      isActive: true,
      category: 'Restaurante',
      rating: 4.8,
      reviewCount: 89,
      openingHours: '11:00 - 23:00',
      deliveryFee: 7.0,
      deliveryTime: 25,
      minimumOrder: 20.0,
      paymentMethods: ['Efectivo', 'Tarjeta'],
      cuisines: ['Sushi', 'Japonesa', 'Asiática'],
      location: {'lat': -12.0464, 'lng': -77.0428},
      createdAt: DateTime.now().subtract(Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<Product> _mockProducts = [
    Product(
      id: 1,
      commerceId: 1,
      name: 'Pizza Margherita',
      description: 'Pizza clásica con tomate, mozzarella y albahaca',
      price: 18.0,
      originalPrice: 22.0,
      image: 'https://via.placeholder.com/300x200',
      category: 'Pizza',
      isAvailable: true,
      stock: 50,
      tags: ['Clásica', 'Vegetariana'],
      nutritionalInfo: {'calories': 266, 'protein': 11, 'carbs': 33},
      allergens: ['Gluten', 'Lácteos'],
      isVegetarian: true,
      isVegan: false,
      isGlutenFree: false,
      preparationTime: 15,
      rating: 4.6,
      reviewCount: 45,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 2,
      commerceId: 1,
      name: 'Pizza Pepperoni',
      description: 'Pizza con pepperoni y queso mozzarella',
      price: 20.0,
      image: 'https://via.placeholder.com/300x200',
      category: 'Pizza',
      isAvailable: true,
      stock: 30,
      tags: ['Popular', 'Carnes'],
      nutritionalInfo: {'calories': 298, 'protein': 14, 'carbs': 35},
      allergens: ['Gluten', 'Lácteos'],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: false,
      preparationTime: 18,
      rating: 4.7,
      reviewCount: 67,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 3,
      commerceId: 2,
      name: 'Sushi California Roll',
      description: 'Roll de cangrejo, aguacate y pepino',
      price: 25.0,
      image: 'https://via.placeholder.com/300x200',
      category: 'Sushi',
      isAvailable: true,
      stock: 25,
      tags: ['Popular', 'Fresco'],
      nutritionalInfo: {'calories': 255, 'protein': 9, 'carbs': 45},
      allergens: ['Pescado', 'Gluten'],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: false,
      preparationTime: 12,
      rating: 4.8,
      reviewCount: 34,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<Order> _mockOrders = [
    Order(
      id: 1,
      userId: 1,
      commerceId: 1,
      orderNumber: 'ORD-001',
      status: 'confirmed',
      subtotal: 38.0,
      deliveryFee: 5.0,
      tax: 2.85,
      total: 45.85,
      paymentMethod: 'Tarjeta',
      paymentStatus: 'paid',
      deliveryAddress: 'Av. Lima 123, Lima',
      specialInstructions: 'Sin cebolla por favor',
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
      createdAt: DateTime.now().subtract(Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(Duration(hours: 1)),
      items: [
        OrderItem(
          id: 1,
          orderId: 1,
          productId: 1,
          productName: 'Pizza Margherita',
          productImage: 'https://via.placeholder.com/100x100',
          price: 18.0,
          quantity: 1,
          total: 18.0,
        ),
        OrderItem(
          id: 2,
          orderId: 1,
          productId: 2,
          productName: 'Pizza Pepperoni',
          productImage: 'https://via.placeholder.com/100x100',
          price: 20.0,
          quantity: 1,
          total: 20.0,
        ),
      ],
    ),
    Order(
      id: 2,
      userId: 2,
      commerceId: 2,
      orderNumber: 'ORD-002',
      status: 'preparing',
      subtotal: 25.0,
      deliveryFee: 7.0,
      tax: 1.88,
      total: 33.88,
      paymentMethod: 'Efectivo',
      paymentStatus: 'pending',
      deliveryAddress: 'Jr. Comercio 456, Lima',
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 25)),
      createdAt: DateTime.now().subtract(Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
      items: [
        OrderItem(
          id: 3,
          orderId: 2,
          productId: 3,
          productName: 'Sushi California Roll',
          productImage: 'https://via.placeholder.com/100x100',
          price: 25.0,
          quantity: 1,
          total: 25.0,
        ),
      ],
    ),
  ];

  // Get all commerces
  Future<List<Commerce>> getCommerces() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/api/commerces'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List).map((json) => Commerce.fromJson(json)).toList();
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 500));
        return _mockCommerces;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return _mockCommerces;
    }
  }

  // Get commerce by ID
  Future<Commerce> getCommerceById(int id) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/commerces/$id');
      // return Commerce.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final commerce = _mockCommerces.firstWhere((c) => c.id == id);
      return commerce;
    } catch (e) {
      throw Exception('Error fetching commerce: $e');
    }
  }

  // Get products by commerce ID
  Future<List<Product>> getProductsByCommerce(int commerceId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/commerces/$commerceId/products');
      // return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockProducts.where((p) => p.commerceId == commerceId).toList();
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/products');
      // return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockProducts;
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get product by ID
  Future<Product> getProductById(int id) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/products/$id');
      // return Product.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final product = _mockProducts.firstWhere((p) => p.id == id);
      return product;
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Create new product
  Future<Product> createProduct(Product product) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/products', product.toJson());
      // return Product.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final newProduct = product.copyWith(
        id: _mockProducts.length + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockProducts.add(newProduct);
      return newProduct;
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(Product product) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/products/${product.id}', product.toJson());
      // return Product.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final updatedProduct = product.copyWith(updatedAt: DateTime.now());
        _mockProducts[index] = updatedProduct;
        return updatedProduct;
      }
      throw Exception('Product not found');
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(int id) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.delete('/products/$id');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      _mockProducts.removeWhere((p) => p.id == id);
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  // Get orders by commerce ID
  Future<List<Order>> getOrdersByCommerce(int commerceId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/commerces/$commerceId/orders');
      // return (response['data'] as List).map((json) => Order.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockOrders.where((o) => o.commerceId == commerceId).toList();
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Update order status
  Future<Order> updateOrderStatus(int orderId, String status) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/orders/$orderId/status', {'status': status});
      // return Order.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updatedOrder = _mockOrders[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        _mockOrders[index] = updatedOrder;
        return updatedOrder;
      }
      throw Exception('Order not found');
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get commerce statistics
  Future<Map<String, dynamic>> getCommerceStatistics(int commerceId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/commerces/$commerceId/statistics');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'total_orders': 156,
        'total_revenue': 23450.0,
        'average_order_value': 150.32,
        'total_products': 45,
        'active_products': 38,
        'total_customers': 89,
        'repeat_customers': 67,
        'average_rating': 4.6,
        'total_reviews': 234,
        'monthly_growth': 12.5,
        'top_products': [
          {'name': 'Pizza Margherita', 'sales': 45},
          {'name': 'Pizza Pepperoni', 'sales': 38},
          {'name': 'Pasta Carbonara', 'sales': 32},
        ],
        'recent_orders': [
          {'order_number': 'ORD-001', 'total': 45.85, 'status': 'confirmed'},
          {'order_number': 'ORD-002', 'total': 33.88, 'status': 'preparing'},
          {'order_number': 'ORD-003', 'total': 28.50, 'status': 'delivered'},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query, {int? commerceId}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/products/search', {'q': query, 'commerce_id': commerceId});
      // return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      var products = _mockProducts;
      if (commerceId != null) {
        products = products.where((p) => p.commerceId == commerceId).toList();
      }
      return products.where((p) => 
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.description.toLowerCase().contains(query.toLowerCase()) ||
        p.category.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Get product categories
  Future<List<String>> getProductCategories() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/products/categories');
      // return List<String>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 200));
      return ['Pizza', 'Sushi', 'Pasta', 'Hamburguesas', 'Bebidas', 'Postres'];
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
} 