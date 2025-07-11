import 'dart:async';
import 'package:zonix/features/services/auth/api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();
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
        {'id': 2, 'name': 'María García', 'role': 'delivery_agent', 'avatar': 'assets/images/profile_photos/user2.jpg'},
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
      // TODO: Replace with real API call
      // final response = await _apiService.get('/chat/conversations');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return _mockConversations;
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  // Get conversation by ID
  Future<Map<String, dynamic>> getConversationById(int conversationId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/chat/conversations/$conversationId');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final conversation = _mockConversations.firstWhere((c) => c['id'] == conversationId);
      return conversation;
    } catch (e) {
      throw Exception('Error fetching conversation: $e');
    }
  }

  // Get messages for conversation
  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/chat/conversations/$conversationId/messages');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockMessages[conversationId] ?? [];
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage(int conversationId, Map<String, dynamic> messageData) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/chat/conversations/$conversationId/messages', messageData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'sender_id': messageData['sender_id'],
        'content': messageData['content'],
        'type': messageData['type'] ?? 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      };
      
      if (!_mockMessages.containsKey(conversationId)) {
        _mockMessages[conversationId] = [];
      }
      _mockMessages[conversationId]!.add(newMessage);
      
      // Update conversation last message
      final conversationIndex = _mockConversations.indexWhere((c) => c['id'] == conversationId);
      if (conversationIndex != -1) {
        _mockConversations[conversationIndex]['last_message'] = newMessage;
        _mockConversations[conversationIndex]['updated_at'] = newMessage['timestamp'];
      }
      
      // Emit message to stream
      _messageController?.add({
        'conversation_id': conversationId,
        'message': newMessage,
      });
      
      return newMessage;
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(int conversationId, List<int> messageIds) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.put('/chat/conversations/$conversationId/messages/read', {
      //   'message_ids': messageIds,
      // });
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      
      if (_mockMessages.containsKey(conversationId)) {
        for (final message in _mockMessages[conversationId]!) {
          if (messageIds.contains(message['id'])) {
            message['read'] = true;
          }
        }
      }
      
      // Update conversation unread count
      final conversationIndex = _mockConversations.indexWhere((c) => c['id'] == conversationId);
      if (conversationIndex != -1) {
        _mockConversations[conversationIndex]['unread_count'] = 0;
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  // Create new conversation
  Future<Map<String, dynamic>> createConversation(Map<String, dynamic> conversationData) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/chat/conversations', conversationData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 800));
      
      final newConversation = {
        'id': _mockConversations.length + 1,
        ...conversationData,
        'last_message': null,
        'unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      _mockConversations.add(newConversation);
      _mockMessages[newConversation['id']] = [];
      
      return newConversation;
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.delete('/chat/conversations/$conversationId');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      _mockConversations.removeWhere((c) => c['id'] == conversationId);
      _mockMessages.remove(conversationId);
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
      // TODO: Replace with real file upload
      // final response = await _apiService.post('/chat/upload', fileData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 1500));
      
      final fileMessage = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'sender_id': fileData['sender_id'],
        'content': fileData['file_url'] ?? 'https://example.com/file.jpg',
        'type': 'file',
        'file_name': fileData['file_name'] ?? 'document.pdf',
        'file_size': fileData['file_size'] ?? 1024,
        'file_type': fileData['file_type'] ?? 'application/pdf',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      };
      
      if (!_mockMessages.containsKey(conversationId)) {
        _mockMessages[conversationId] = [];
      }
      _mockMessages[conversationId]!.add(fileMessage);
      
      return fileMessage;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/chat/statistics');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      
      int totalMessages = 0;
      int unreadMessages = 0;
      
      for (final conversation in _mockConversations) {
        totalMessages += conversation['last_message'] != null ? 1 : 0;
        unreadMessages += conversation['unread_count'] ?? 0;
      }
      
      return {
        'total_conversations': _mockConversations.length,
        'total_messages': totalMessages,
        'unread_messages': unreadMessages,
        'active_conversations': _mockConversations.where((c) => c['updated_at'] != null).length,
        'response_time_avg': 2.5, // minutes
        'satisfaction_rate': 4.8, // out of 5
      };
    } catch (e) {
      throw Exception('Error fetching chat statistics: $e');
    }
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/chat/search', {'q': query});
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
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
    } catch (e) {
      throw Exception('Error searching messages: $e');
    }
  }

  // Block user
  Future<void> blockUser(int userId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.post('/chat/block', {'user_id': userId});
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      print('User $userId blocked');
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  // Unblock user
  Future<void> unblockUser(int userId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.delete('/chat/block/$userId');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      print('User $userId unblocked');
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  // Get blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/chat/blocked');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return [
        {
          'id': 5,
          'name': 'Usuario Problemático',
          'avatar': 'assets/images/profile_photos/user5.jpg',
          'blocked_at': '2024-01-10T15:30:00',
        },
      ];
    } catch (e) {
      throw Exception('Error fetching blocked users: $e');
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