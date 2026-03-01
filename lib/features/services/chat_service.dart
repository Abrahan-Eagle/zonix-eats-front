import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class ChatService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _typingTimer;

  // Get conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/conversations'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error fetching conversations: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      debugPrint('Warning: Error marking messages as read: $e');
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
      rethrow;
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
    _typingTimer = Timer(const Duration(seconds: 5), () {
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
    
    // TODO: Implementar tiempo real con Pusher (canal de chat)
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
    
    // TODO: Desconectar Pusher (canal de chat)
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
          'content': fileData['file_url'] ?? fileData['content'] ?? '',
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
      };
    } catch (e) {
      rethrow;
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
      rethrow;
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