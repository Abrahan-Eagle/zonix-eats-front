import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';
import 'websocket_service.dart';

class ChatService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  final WebSocketService _webSocketService = WebSocketService();
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _typingTimer;
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockConversations = [
    {
      'id': 1,
      'type': 'order',
      'order_id': 123,
      'participants': [
        {'id': 1, 'name': 'Juan Pérez', 'role': 'customer', 'avatar': 'assets/images/profile_photos/user1.jpg'},
        {'id': 2, 'name': 'María García', 'role': 'delivery', 'avatar': 'assets/images/profile_photos/user2.jpg'},
      ],
      'last_message': {
        'id': 15,
        'sender_id': 2,
        'content': '¡Hola! Estoy en camino con tu pedido. Llegaré en 10 minutos.',
        'type': 'text',
        'timestamp': '2024-01-15T10:45:00',
        'read': true,
      },
      'unread_count': 0,
      'created_at': '2024-01-15T10:30:00',
      'updated_at': '2024-01-15T10:45:00',
    },
    {
      'id': 2,
      'type': 'support',
      'subject': 'Problema con mi pedido',
      'participants': [
        {'id': 1, 'name': 'Juan Pérez', 'role': 'customer', 'avatar': 'assets/images/profile_photos/user1.jpg'},
        {'id': 3, 'name': 'Soporte ZONIX', 'role': 'support', 'avatar': 'assets/images/profile_photos/support.jpg'},
      ],
      'last_message': {
        'id': 8,
        'sender_id': 3,
        'content': 'Hemos procesado tu reembolso. Debería aparecer en tu cuenta en 3-5 días hábiles.',
        'type': 'text',
        'timestamp': '2024-01-15T09:30:00',
        'read': false,
      },
      'unread_count': 1,
      'created_at': '2024-01-15T08:00:00',
      'updated_at': '2024-01-15T09:30:00',
    },
    {
      'id': 3,
      'type': 'commerce',
      'commerce_id': 5,
      'participants': [
        {'id': 1, 'name': 'Juan Pérez', 'role': 'customer', 'avatar': 'assets/images/profile_photos/user1.jpg'},
        {'id': 4, 'name': 'Restaurante El Buen Sabor', 'role': 'commerce', 'avatar': 'assets/images/profile_photos/commerce1.jpg'},
      ],
      'last_message': {
        'id': 12,
        'sender_id': 4,
        'content': '¡Gracias por tu pedido! Lo estamos preparando con mucho cuidado.',
        'type': 'text',
        'timestamp': '2024-01-15T10:35:00',
        'read': true,
      },
      'unread_count': 0,
      'created_at': '2024-01-15T10:25:00',
      'updated_at': '2024-01-15T10:35:00',
    },
  ];

  static final Map<int, List<Map<String, dynamic>>> _mockMessages = {
    1: [
      {
        'id': 1,
        'sender_id': 1,
        'content': 'Hola, ¿cuándo llegará mi pedido?',
        'type': 'text',
        'timestamp': '2024-01-15T10:30:00',
        'read': true,
      },
      {
        'id': 2,
        'sender_id': 2,
        'content': 'Hola Juan, tu pedido está siendo preparado. Te avisaré cuando salga para entrega.',
        'type': 'text',
        'timestamp': '2024-01-15T10:32:00',
        'read': true,
      },
      {
        'id': 3,
        'sender_id': 2,
        'content': 'Tu pedido ya está en camino. ETA: 15 minutos.',
        'type': 'text',
        'timestamp': '2024-01-15T10:40:00',
        'read': true,
      },
      {
        'id': 15,
        'sender_id': 2,
        'content': '¡Hola! Estoy en camino con tu pedido. Llegaré en 10 minutos.',
        'type': 'text',
        'timestamp': '2024-01-15T10:45:00',
        'read': true,
      },
    ],
    2: [
      {
        'id': 4,
        'sender_id': 1,
        'content': 'Hola, tengo un problema con mi pedido anterior.',
        'type': 'text',
        'timestamp': '2024-01-15T08:00:00',
        'read': true,
      },
      {
        'id': 5,
        'sender_id': 3,
        'content': 'Hola Juan, ¿en qué puedo ayudarte?',
        'type': 'text',
        'timestamp': '2024-01-15T08:05:00',
        'read': true,
      },
      {
        'id': 6,
        'sender_id': 1,
        'content': 'Mi comida llegó fría y faltaba un item.',
        'type': 'text',
        'timestamp': '2024-01-15T08:10:00',
        'read': true,
      },
      {
        'id': 7,
        'sender_id': 3,
        'content': 'Entiendo, me disculpo por la inconveniencia. ¿Podrías proporcionarme el número de orden?',
        'type': 'text',
        'timestamp': '2024-01-15T08:15:00',
        'read': true,
      },
      {
        'id': 8,
        'sender_id': 3,
        'content': 'Hemos procesado tu reembolso. Debería aparecer en tu cuenta en 3-5 días hábiles.',
        'type': 'text',
        'timestamp': '2024-01-15T09:30:00',
        'read': false,
      },
    ],
    3: [
      {
        'id': 9,
        'sender_id': 1,
        'content': '¿Pueden hacer mi hamburguesa sin cebolla?',
        'type': 'text',
        'timestamp': '2024-01-15T10:25:00',
        'read': true,
      },
      {
        'id': 10,
        'sender_id': 4,
        'content': '¡Por supuesto! Lo anotamos en tu pedido.',
        'type': 'text',
        'timestamp': '2024-01-15T10:28:00',
        'read': true,
      },
      {
        'id': 11,
        'sender_id': 1,
        'content': 'Perfecto, gracias.',
        'type': 'text',
        'timestamp': '2024-01-15T10:30:00',
        'read': true,
      },
      {
        'id': 12,
        'sender_id': 4,
        'content': '¡Gracias por tu pedido! Lo estamos preparando con mucho cuidado.',
        'type': 'text',
        'timestamp': '2024-01-15T10:35:00',
        'read': true,
      },
    ],
  };

  // Get conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/conversations'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 500));
        return _mockConversations;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return _mockConversations;
    }
  }

  // Get conversation by ID
  Future<Map<String, dynamic>> getConversationById(int conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final messages = jsonDecode(response.body);
        // Construir objeto conversación desde los mensajes
        if (messages is List && messages.isNotEmpty) {
          final firstMessage = messages[0];
          return {
            'id': conversationId,
            'order_id': firstMessage['order_id'] ?? conversationId,
            'messages': messages,
          };
        }
        // Si no hay mensajes, obtener info de la conversación desde getConversations
        final conversations = await getConversations();
        return conversations.firstWhere(
          (c) => c['id'] == conversationId || c['order_id'] == conversationId,
          orElse: () => {'id': conversationId, 'order_id': conversationId},
        );
      } else {
        throw Exception('Error fetching conversation: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 300));
      try {
        return _mockConversations.firstWhere((c) => c['id'] == conversationId);
      } catch (_) {
        throw Exception('Error fetching conversation: $e');
      }
    }
  }

  // Get messages for conversation
  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error fetching messages: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      return _mockMessages[conversationId] ?? [];
    }
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage(int conversationId, Map<String, dynamic> messageData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'content': messageData['content'] ?? messageData['message'] ?? '',
          'type': messageData['type'] ?? 'text',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMessage = data is Map ? Map<String, dynamic>.from(data) : {
          'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'sender_id': data['sender_id'],
          'content': data['content'] ?? messageData['content'],
          'type': data['type'] ?? messageData['type'] ?? 'text',
          'timestamp': data['created_at'] ?? DateTime.now().toIso8601String(),
          'read': data['read_at'] != null,
        };
        
        // Emit message to stream
        _messageController?.add({
          'conversation_id': conversationId,
          'message': newMessage,
        });
        
        notifyListeners();
        return newMessage;
      } else {
        throw Exception('Error sending message: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'sender_id': messageData['sender_id'],
        'content': messageData['content'] ?? messageData['message'] ?? '',
        'type': messageData['type'] ?? 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      };
      
      // Emit message to stream
      _messageController?.add({
        'conversation_id': conversationId,
        'message': newMessage,
      });
      
      return newMessage;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(int conversationId, List<int> messageIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/read'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return;
      } else {
        throw Exception('Error marking messages as read: ${response.statusCode}');
      }
    } catch (e) {
      // No crítico si falla, solo log
      print('Warning: Error marking messages as read: $e');
    }
  }

  // Create new conversation
  Future<Map<String, dynamic>> createConversation(Map<String, dynamic> conversationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'order_id': conversationData['order_id'] ?? conversationData['id'],
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newConversation = data is Map ? Map<String, dynamic>.from(data) : {
          'id': data['id'] ?? conversationData['order_id'],
          'order_id': data['order_id'] ?? conversationData['order_id'],
          'type': 'order',
          'last_message': null,
          'unread_count': 0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
        };
        
        notifyListeners();
        return newConversation;
      } else {
        throw Exception('Error creating conversation: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 800));
      final newConversation = {
        'id': conversationData['order_id'] ?? conversationData['id'] ?? _mockConversations.length + 1,
        'order_id': conversationData['order_id'] ?? conversationData['id'],
        'type': 'order',
        'last_message': null,
        'unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      return newConversation;
    }
  }

  // Delete conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return;
      } else {
        throw Exception('Error deleting conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting conversation: $e');
    }
  }

  // Start typing indicator
  void startTyping(int conversationId, int userId) {
    // TODO: Implement real-time typing indicator
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 5), () {
      stopTyping(conversationId, userId);
    });
  }

  // Stop typing indicator
  void stopTyping(int conversationId, int userId) {
    _typingTimer?.cancel();
    // TODO: Implement real-time typing indicator
  }

  // Get message stream
  Stream<Map<String, dynamic>>? get messageStream {
    return _messageController?.stream;
  }

  // Start listening for new messages
  void startListening() {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    
    // TODO: Implement real-time WebSocket connection
    // _socket = io.connect('ws://your-server.com/chat');
    // _socket.on('new_message', (data) {
    //   _messageController?.add(data);
    // });
  }

  // Stop listening for new messages
  void stopListening() {
    _messageController?.close();
    _messageController = null;
    _typingTimer?.cancel();
    
    // TODO: Disconnect WebSocket
    // _socket?.disconnect();
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(int conversationId, Map<String, dynamic> fileData) async {
    try {
      // TODO: Implementar subida de archivos con multipart/form-data
      // Por ahora solo se puede enviar como mensaje de tipo 'image' con URL
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'content': fileData['file_url'] ?? fileData['content'] ?? '',
          'type': fileData['type'] ?? 'image',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fileMessage = data is Map ? Map<String, dynamic>.from(data) : {
          'id': DateTime.now().millisecondsSinceEpoch,
          'sender_id': fileData['sender_id'],
          'content': fileData['file_url'] ?? 'https://example.com/file.jpg',
          'type': 'image',
          'file_name': fileData['file_name'] ?? 'file.jpg',
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        };
        
        notifyListeners();
        return fileMessage;
      } else {
        throw Exception('Error uploading file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      // Calcular estadísticas desde las conversaciones obtenidas
      final conversations = await getConversations();
      
      int totalMessages = 0;
      int unreadMessages = 0;
      
      for (final conversation in conversations) {
        if (conversation['last_message'] != null) {
          totalMessages++;
        }
        unreadMessages += (conversation['unread_count'] as int?) ?? 0;
      }
      
      return {
        'total_conversations': conversations.length,
        'total_messages': totalMessages,
        'unread_messages': unreadMessages,
        'active_conversations': conversations.where((c) => c['updated_at'] != null).length,
        'response_time_avg': 2.5, // TODO: Calcular desde mensajes reales
        'satisfaction_rate': 4.8, // TODO: Calcular desde reviews
      };
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'total_conversations': _mockConversations.length,
        'total_messages': _mockConversations.length,
        'unread_messages': 0,
        'active_conversations': _mockConversations.length,
        'response_time_avg': 2.5,
        'satisfaction_rate': 4.8,
      };
    }
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat/search').replace(queryParameters: {
        'q': query,
      });

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error searching messages: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      final results = <Map<String, dynamic>>[];
      
      for (final conversation in _mockConversations) {
        final conversationId = conversation['id'];
        if (_mockMessages.containsKey(conversationId)) {
          for (final message in _mockMessages[conversationId]!) {
            if (message['content'].toString().toLowerCase().contains(query.toLowerCase())) {
              results.add({
                'conversation': conversation,
                'message': message,
              });
            }
          }
        }
      }
      
      return results;
    }
  }

  // Block user
  Future<void> blockUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/block'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return;
      } else {
        throw Exception('Error blocking user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  // Unblock user
  Future<void> unblockUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/block/$userId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return;
      } else {
        throw Exception('Error unblocking user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  // Get blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/blocked-users'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Si retorna lista de IDs, convertir a lista de objetos
          if (data.isNotEmpty && data[0] is int) {
            return data.map((id) => {'id': id}).toList();
          }
          return List<Map<String, dynamic>>.from(data);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        // Retornar lista vacía si no está implementado
        return [];
      }
    } catch (e) {
      // Retornar lista vacía en caso de error (no crítico)
      return [];
    }
  }

  // Format message timestamp
  String formatMessageTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  // Check if message is from today
  bool isMessageFromToday(String timestamp) {
    final messageDate = DateTime.parse(timestamp);
    final today = DateTime.now();
    return messageDate.year == today.year &&
           messageDate.month == today.month &&
           messageDate.day == today.day;
  }

  // Get message status icon
  String getMessageStatusIcon(Map<String, dynamic> message) {
    if (message['read'] == true) {
      return '✓✓'; // Double check for read
    } else {
      return '✓'; // Single check for sent
    }
  }
} 