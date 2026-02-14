import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';
import 'package:http_parser/http_parser.dart';
import '../../features/utils/auth_utils.dart';

class OrderService extends ChangeNotifier {
  final String _baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

  // POST /api/buyer/orders - Crear orden
  /// [deliveryType] 'pickup' o 'delivery'
  /// [deliveryAddress] requerido cuando deliveryType es 'delivery'
  Future<Order> createOrder(
    List<CartItem> items, {
    required String deliveryType,
    String? deliveryAddress,
  }) async {
    if (items.isEmpty) {
      throw Exception('El carrito está vacío');
    }
    final commerceId = items.first.commerceId;
    if (commerceId == null) {
      throw Exception('No se pudo identificar el comercio. Agrega productos desde el detalle del restaurante.');
    }
    if (deliveryType == 'delivery' && (deliveryAddress == null || deliveryAddress.trim().isEmpty)) {
      throw Exception('La dirección de entrega es requerida para envío a domicilio.');
    }
    final total = items.fold<double>(0, (sum, i) => sum + (i.precio ?? 0) * i.quantity);
    final orderNotes = items
        .where((i) => i.notes != null && i.notes!.isNotEmpty)
        .map((i) => '${i.nombre}: ${i.notes}')
        .join('; ');
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders');
    final body = jsonEncode({
      'commerce_id': commerceId,
      'products': items.map((e) => {'id': e.id, 'quantity': e.quantity}).toList(),
      'delivery_type': deliveryType,
      'total': total,
      if (orderNotes.isNotEmpty) 'notes': orderNotes,
      if (deliveryType == 'delivery') 'delivery_address': deliveryAddress?.trim() ?? '',
    });
    
    final response = await http.post(
      url,
      body: body,
      headers: headers,
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      } else {
        // Manejar errores específicos del backend
        String errorMessage = data['message'] ?? 'Error al crear la orden';
        if (data['missing_field'] != null) {
          // Si falta un campo requerido (ej: photo_users), mostrar mensaje específico
          if (data['missing_field'] == 'photo_users') {
            errorMessage = 'Se requiere una foto de perfil para crear una orden. Por favor, completa tu perfil.';
          } else {
            errorMessage = 'Se requiere ${data['missing_field']} para crear una orden. Por favor, completa tu perfil.';
          }
        }
        throw Exception(errorMessage);
      }
    } else {
      // Manejar códigos de error HTTP específicos
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      String errorMessage = 'Error al crear la orden: ${response.statusCode}';
      
      if (data != null && data['message'] != null) {
        errorMessage = data['message'];
        // Detectar si falta photo_users
        if (data['missing_field'] == 'photo_users' || 
            (errorMessage.contains('photo_users') || errorMessage.contains('foto'))) {
          errorMessage = 'Se requiere una foto de perfil para crear una orden. Por favor, completa tu perfil.';
        }
      }
      
      throw Exception(errorMessage);
    }
  }

  // GET /api/buyer/orders - Listar órdenes del usuario
  Future<List<Order>> fetchOrders() async {
    final headers = await AuthHelper.getAuthHeaders();
    // Obtener el rol del usuario
    final userRole = await AuthUtils.getUserRole();
    final isCommerce = userRole == 'commerce';
    final url = isCommerce
        ? Uri.parse('${AppConfig.apiUrl}/api/commerce/orders')
        : Uri.parse('${AppConfig.apiUrl}/api/buyer/orders');
    
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Handle different response structures
      List<dynamic> ordersData;
      
      if (data is Map<String, dynamic>) {
        // Check if it's wrapped in success/data structure
        if (data['success'] == true && data['data'] != null) {
          ordersData = data['data'];
        } else {
          // If it's a map but not wrapped, check if it contains orders
          if (data.containsKey('orders')) {
            ordersData = data['orders'];
          } else {
            return [];
          }
        }
      } else if (data is List) {
        // If backend returns an array directly
        ordersData = data;
      } else {
        return [];
      }
      
      if (ordersData is List) {
        try {
          return ordersData.map<Order>((item) {
            return Order.fromJson(item);
          }).toList();
        } catch (e) {
          throw Exception('Error processing orders: $e');
        }
      } else {
        return [];
      }
    } else {
      throw Exception('Error al obtener órdenes: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders/{id} - Obtener detalle de orden específica
  Future<Order> getOrderById(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener la orden');
      }
    } else {
      throw Exception('Error al obtener la orden: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/payment-proof - Subir comprobante de pago
  Future<void> uploadPaymentProof(int orderId, String filePath, String fileType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/payment-proof');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    
    request.files.add(await http.MultipartFile.fromPath(
      'payment_proof', 
      filePath, 
      contentType: fileType == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', fileType)
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al subir comprobante de pago');
      }
    } else {
      throw Exception('Error al subir comprobante de pago: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/cancel - Cancelar orden
  // Nota: El backend valida que solo se puede cancelar en pending_payment y dentro de 5 minutos
  Future<void> cancelOrder(int orderId, {String? reason}) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/cancel');
    
    final body = reason != null ? jsonEncode({'reason': reason}) : jsonEncode({'reason': 'Cancelación por usuario'});
    
    final response = await http.post(
      url,
      body: body,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        // Manejar errores específicos (ej: tiempo límite expirado)
        String errorMessage = data['message'] ?? 'Error al cancelar la orden';
        throw Exception(errorMessage);
      }
    } else {
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      String errorMessage = data?['message'] ?? 'Error al cancelar la orden: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  // POST /api/buyer/orders/{id}/comprobante - Subir comprobante (método alternativo)
  Future<void> uploadComprobante(int orderId, String filePath, String fileType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/comprobante');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    
    request.files.add(await http.MultipartFile.fromPath(
      'comprobante', 
      filePath, 
      contentType: fileType == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', fileType)
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al subir comprobante');
      }
    } else {
      throw Exception('Error al subir comprobante: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders/{orderId}/tracking - Obtener tracking de la orden
  Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/tracking');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Error al obtener tracking');
      }
    } else {
      throw Exception('Error al obtener tracking: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/tracking/location - Actualizar ubicación del tracking
  Future<void> updateTrackingLocation(int orderId, double latitude, double longitude) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/tracking/location');
    final response = await http.post(
      url,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al actualizar ubicación');
      }
    } else {
      throw Exception('Error al actualizar ubicación: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders/{orderId}/messages - Obtener mensajes de la orden
  Future<List<Map<String, dynamic>>> getOrderMessages(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/messages');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener mensajes');
      }
    } else {
      throw Exception('Error al obtener mensajes: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{orderId}/messages - Enviar mensaje a la orden
  Future<void> sendOrderMessage(int orderId, String message) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/messages');
    final response = await http.post(
      url,
      body: jsonEncode({
        'message': message,
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al enviar mensaje');
      }
    } else {
      throw Exception('Error al enviar mensaje: ${response.statusCode}');
    }
  }

  // Método para validar comprobante (para comercios)
  Future<void> validarComprobante(int orderId, String accion) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/commerce/orders/$orderId/validar-comprobante');
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'accion': accion})
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al validar comprobante');
      }
    } else {
      throw Exception('Error al validar comprobante: ${response.statusCode}');
    }
  }

  // Alias method for getUserOrders to maintain compatibility
  Future<List<Order>> getUserOrders() async {
    return await fetchOrders();
  }
}
