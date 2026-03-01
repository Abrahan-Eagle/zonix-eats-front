import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';
import 'package:http_parser/http_parser.dart';
import '../../features/utils/auth_utils.dart';

class OrderService extends ChangeNotifier {
  // POST /api/buyer/orders - Crear orden
  /// [deliveryType] 'pickup' o 'delivery'
  /// [deliveryAddress] requerido cuando deliveryType es 'delivery'
  /// [deliveryFee] opcional, costo de envío (ej. 2.50). 0 si pickup.
  Future<Order> createOrder(
    List<CartItem> items, {
    required String deliveryType,
    String? deliveryAddress,
    double deliveryFee = 0.0,
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
    final subtotal = items.fold<double>(0, (sum, i) => sum + (i.precio ?? 0) * i.quantity);
    final total = subtotal + (deliveryFee > 0 ? deliveryFee : 0.0);
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
      'delivery_fee': deliveryFee,
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
        } else if (data.containsKey('data') && data['data'] is List) {
          // Laravel paginator: { data: [...], current_page, total, ... }
          ordersData = data['data'] as List<dynamic>;
        } else if (data.containsKey('orders')) {
          ordersData = data['orders'];
        } else {
          return [];
        }
      } else if (data is List) {
        // If backend returns an array directly
        ordersData = data;
      } else {
        return [];
      }
      
      try {
        return ordersData.map<Order>((item) {
          return Order.fromJson(item);
        }).toList();
      } catch (e) {
        throw Exception('Error processing orders: $e');
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
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) throw Exception('Respuesta inválida');
      if (data['error'] != null) throw Exception(data['error'].toString());
      // Backend devuelve { success: true, data: order } o la orden directamente
      final orderMap = (data['success'] == true && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : data;
      return Order.fromJson(orderMap);
    } else {
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final msg = data is Map ? (data['message'] ?? data['error']) : null;
      throw Exception(msg?.toString() ?? 'Error al obtener la orden: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/payment-proof - Subir comprobante de pago
  /// [paymentMethod] requerido por backend (ej. efectivo, transferencia, tarjeta)
  /// [referenceNumber] número de referencia/transacción
  Future<void> uploadPaymentProof(
    int orderId,
    String filePath,
    String fileType, {
    required String paymentMethod,
    required String referenceNumber,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/payment-proof');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    
    request.files.add(await http.MultipartFile.fromPath(
      'payment_proof', 
      filePath, 
      contentType: fileType == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', fileType)
    ));
    request.fields['payment_method'] = paymentMethod;
    request.fields['reference_number'] = referenceNumber;
    
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
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data != null && (data['success'] == true || data['message'] != null)) return;
      if (data != null) {
        String errorMessage = data['message']?.toString() ?? 'Error al cancelar la orden';
        throw Exception(errorMessage);
      }
      return;
    } else {
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      String errorMessage = data?['message'] ?? 'Error al cancelar la orden: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  // POST /api/buyer/orders/{id}/comprobante - Subir comprobante (alias de uploadPaymentProof)
  Future<void> uploadComprobante(
    int orderId,
    String filePath,
    String fileType, {
    String paymentMethod = 'otro',
    String referenceNumber = '',
  }) async {
    return uploadPaymentProof(
      orderId,
      filePath,
      fileType,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber.isEmpty ? 'N/A' : referenceNumber,
    );
  }

  // GET /api/buyer/orders/{orderId}/tracking - Obtener tracking de la orden
  /// Devuelve un map con al menos [latitude] y [longitude] (ubicación del repartidor).
  Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/tracking');
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener tracking: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Error al obtener tracking');
    }

    final dataPayload = data['data'];
    final trackingPayload = data['tracking'];
    if (dataPayload != null && dataPayload is Map) {
      final lat = dataPayload['latitude'];
      final lng = dataPayload['longitude'];
      return {
        'latitude': lat is num ? lat.toDouble() : (lat != null ? double.tryParse(lat.toString()) : null),
        'longitude': lng is num ? lng.toDouble() : (lng != null ? double.tryParse(lng.toString()) : null),
        ...Map<String, dynamic>.from(dataPayload),
      };
    }
    if (trackingPayload != null && trackingPayload is Map) {
      final dl = trackingPayload['delivery_location'];
      if (dl is Map) {
        final lat = dl['lat'];
        final lng = dl['lng'];
        return {
          'latitude': lat is num ? lat.toDouble() : (lat != null ? double.tryParse(lat.toString()) : null),
          'longitude': lng is num ? lng.toDouble() : (lng != null ? double.tryParse(lng.toString()) : null),
        };
      }
    }
    return {};
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
  /// Compatible con Chat\ChatController (array directo) y formato { success, data }
  Future<List<Map<String, dynamic>>> getOrderMessages(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/messages');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      if (data is Map && data['success'] == true) {
        final list = data['data'] ?? data['messages'];
        if (list != null && list is List) {
          return List<Map<String, dynamic>>.from(list);
        }
        return [];
      }
      throw Exception(data['message'] ?? 'Error al obtener mensajes');
    } else {
      throw Exception('Error al obtener mensajes: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{orderId}/messages - Enviar mensaje a la orden
  /// Envía 'content' para compatibilidad con Chat\ChatController
  Future<void> sendOrderMessage(int orderId, String message) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders/$orderId/messages');
    final response = await http.post(
      url,
      body: jsonEncode({
        'content': message,
      }),
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
