import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class ScheduledOrderService {
  static const String baseUrl = AppConfig.baseUrl;
  static const int requestTimeout = AppConfig.requestTimeout;

  /// Crear pedido programado
  static Future<Map<String, dynamic>> createScheduledOrder({
    required int commerceId,
    required List<Map<String, dynamic>> items,
    required String scheduledDate,
    required String scheduledTime,
    required String deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/scheduled-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'commerce_id': commerceId,
          'items': items,
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod,
          'notes': notes,
        }),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear pedido programado');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener pedidos programados del usuario
  static Future<Map<String, dynamic>> getScheduledOrders() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/scheduled-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener pedidos programados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener ventanas de entrega disponibles
  static Future<Map<String, dynamic>> getAvailableDeliveryWindows({
    required String date,
    required int commerceId,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/scheduled-orders/delivery-windows?date=$date&commerce_id=$commerceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener ventanas de entrega: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Cancelar pedido programado
  static Future<Map<String, dynamic>> cancelScheduledOrder(int orderId) async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/buyer/scheduled-orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cancelar pedido programado');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Modificar pedido programado
  static Future<Map<String, dynamic>> updateScheduledOrder({
    required int orderId,
    String? scheduledDate,
    String? scheduledTime,
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      final Map<String, dynamic> updateData = {};
      
      if (scheduledDate != null) updateData['scheduled_date'] = scheduledDate;
      if (scheduledTime != null) updateData['scheduled_time'] = scheduledTime;
      if (deliveryAddress != null) updateData['delivery_address'] = deliveryAddress;
      if (notes != null) updateData['notes'] = notes;

      final response = await http.put(
        Uri.parse('$baseUrl/api/buyer/scheduled-orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al modificar pedido programado');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener estadísticas de pedidos programados
  static Future<Map<String, dynamic>> getScheduledOrderStats() async {
    try {
      final token = await AuthHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/scheduled-orders/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Verificar si se puede cancelar un pedido programado
  static bool canCancelScheduledOrder(DateTime scheduledDateTime) {
    final now = DateTime.now();
    final hoursUntilDelivery = scheduledDateTime.difference(now).inHours;
    return hoursUntilDelivery >= 2;
  }

  /// Verificar si se puede modificar un pedido programado
  static bool canModifyScheduledOrder(DateTime scheduledDateTime) {
    final now = DateTime.now();
    final hoursUntilDelivery = scheduledDateTime.difference(now).inHours;
    return hoursUntilDelivery >= 2;
  }

  /// Calcular tiempo restante hasta la entrega
  static Map<String, int> calculateTimeUntilDelivery(DateTime scheduledDateTime) {
    final now = DateTime.now();
    final difference = scheduledDateTime.difference(now);
    
    if (difference.isNegative) {
      return {'days': 0, 'hours': 0, 'minutes': 0};
    }
    
    return {
      'days': difference.inDays,
      'hours': difference.inHours % 24,
      'minutes': difference.inMinutes % 60,
    };
  }

  /// Formatear fecha y hora para mostrar
  static String formatScheduledDateTime(String date, String time) {
    final dateTime = DateTime.parse('$date $time');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} a las ${time}';
  }

  /// Obtener estado del pedido programado
  static String getScheduledOrderStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Programado';
      case 'confirmed':
        return 'Confirmado';
      case 'preparing':
        return 'Preparando';
      case 'ready':
        return 'Listo';
      case 'delivering':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  /// Obtener color del estado del pedido
  static String getScheduledOrderStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return '#FFA500'; // Naranja
      case 'confirmed':
        return '#0000FF'; // Azul
      case 'preparing':
        return '#FFD700'; // Dorado
      case 'ready':
        return '#32CD32'; // Verde lima
      case 'delivering':
        return '#FF69B4'; // Rosa
      case 'delivered':
        return '#008000'; // Verde
      case 'cancelled':
        return '#FF0000'; // Rojo
      default:
        return '#808080'; // Gris
    }
  }

  /// Validar fecha y hora de programación
  static bool isValidScheduledDateTime(String date, String time) {
    try {
      final scheduledDateTime = DateTime.parse('$date $time');
      final now = DateTime.now();
      
      // Debe ser al menos 2 horas en el futuro
      final minimumDateTime = now.add(Duration(hours: 2));
      
      return scheduledDateTime.isAfter(minimumDateTime);
    } catch (e) {
      return false;
    }
  }

  /// Obtener ventanas de tiempo sugeridas
  static List<Map<String, String>> getSuggestedTimeWindows() {
    final now = DateTime.now();
    final suggestions = <Map<String, String>>[];
    
    // Sugerir ventanas para los próximos 3 días
    for (int day = 1; day <= 3; day++) {
      final date = now.add(Duration(days: day));
      
      // Ventanas de 30 minutos desde las 8 AM hasta las 10 PM
      for (int hour = 8; hour <= 22; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          suggestions.add({
            'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'time': time,
            'display': '${date.day}/${date.month} a las $time',
          });
        }
      }
    }
    
    return suggestions;
  }
} 