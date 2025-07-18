import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class BuyerChatService {
  final Logger _logger = Logger();

  // GET /api/buyer/chat/messages/{orderId} - Obtener mensajes del chat de una orden
  Future<List<Map<String, dynamic>>> getChatMessages(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/chat/messages/$orderId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener mensajes: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getChatMessages: $e');
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  // POST /api/buyer/chat/send - Enviar mensaje
  Future<Map<String, dynamic>> sendMessage({
    required int orderId,
    required String message,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/chat/send');
      
      final body = {
        'order_id': orderId,
        'message': message,
        if (messageType != null) 'message_type': messageType,
        if (metadata != null) 'metadata': metadata,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al enviar mensaje');
        }
      } else {
        throw Exception('Error al enviar mensaje: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en sendMessage: $e');
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  // POST /api/buyer/chat/mark-read - Marcar mensajes como leídos
  Future<bool> markAsRead({
    required int orderId,
    List<int>? messageIds,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/chat/mark-read');
      
      final body = {
        'order_id': orderId,
        if (messageIds != null) 'message_ids': messageIds,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Error al marcar como leído: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en markAsRead: $e');
      throw Exception('Error al marcar como leído: $e');
    }
  }

  // GET /api/buyer/chat/unread/{orderId} - Obtener mensajes no leídos
  Future<List<Map<String, dynamic>>> getUnreadMessages(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/chat/unread/$orderId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener mensajes no leídos: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getUnreadMessages: $e');
      throw Exception('Error al obtener mensajes no leídos: $e');
    }
  }
} 