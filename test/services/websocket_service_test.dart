import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/websocket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('WebSocketService Tests', () {
    late WebSocketService webSocketService;

    setUp(() {
      webSocketService = WebSocketService();
    });

    test('WebSocketService should be properly initialized', () {
      expect(webSocketService, isNotNull);
    });

    test('WebSocketService should have correct structure', () {
      expect(webSocketService, isA<WebSocketService>());
    });

    test('WebSocketService should handle connection status', () {
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('WebSocketService should handle disconnect safely', () {
      expect(() => webSocketService.disconnect(), returnsNormally);
    });

    test('WebSocketService should handle connection attempts', () {
      expect(() => webSocketService.connect(), returnsNormally);
    });

    test('WebSocketService should handle multiple disconnect calls', () {
      expect(() => webSocketService.disconnect(), returnsNormally);
      expect(() => webSocketService.disconnect(), returnsNormally);
    });
  });
} 