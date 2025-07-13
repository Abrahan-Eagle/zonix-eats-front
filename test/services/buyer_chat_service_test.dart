import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/buyer_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BuyerChatService Tests', () {
    late BuyerChatService chatService;

    setUp(() {
      chatService = BuyerChatService();
    });

    test('BuyerChatService should be properly initialized', () {
      expect(chatService, isNotNull);
    });

    test('BuyerChatService should have correct structure', () {
      expect(chatService, isA<BuyerChatService>());
    });

    test('BuyerChatService should handle getChatMessages', () {
      expect(chatService.getChatMessages, isA<Function>());
    });

    test('BuyerChatService should handle sendMessage', () {
      expect(chatService.sendMessage, isA<Function>());
    });

    test('BuyerChatService should handle markAsRead', () {
      expect(chatService.markAsRead, isA<Function>());
    });

    test('BuyerChatService should handle getUnreadMessages', () {
      expect(chatService.getUnreadMessages, isA<Function>());
    });
  });
} 