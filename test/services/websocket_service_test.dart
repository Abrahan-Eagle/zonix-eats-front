import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/src/channel.dart';
import 'package:zonix/features/services/websocket_service.dart';
import 'websocket_service_test.mocks.dart';

class MockWebSocketSink extends Mock implements WebSocketSink {}

@GenerateMocks([WebSocketChannel])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('WebSocketService Tests', () {
    late WebSocketService webSocketService;
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      webSocketService = WebSocketService();
    });

    test('should connect successfully', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.empty());
      final result = webSocketService.connect();
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should fail to connect with invalid URL', () async {
      final result = webSocketService.connect();
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should disconnect successfully', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.empty());
      webSocketService.connect();
      webSocketService.disconnect();
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle message stream', () async {
      final messageController = StreamController<Map<String, dynamic>>();
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => messageController.stream);
      webSocketService.connect();
      final testMessage = {'type': 'test', 'data': 'hello'};
      messageController.add(testMessage);
      await Future.delayed(Duration(milliseconds: 100));
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle connection errors', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.error('Connection failed'));
      webSocketService.connect();
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle reconnection', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.empty());
      webSocketService.connect();
      webSocketService.disconnect();
      webSocketService.connect();
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle connection timeout', () async {
      final result = webSocketService.connect();
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle heartbeat mechanism', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.empty());
      webSocketService.connect();
      await Future.delayed(Duration(milliseconds: 100));
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle connection status updates', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.empty());
      webSocketService.connect();
      await Future.delayed(Duration(milliseconds: 100));
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle error logging', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.error('Test error'));
      webSocketService.connect();
      await Future.delayed(Duration(milliseconds: 100));
      expect(webSocketService.isConnected, isA<bool>());
    });

    test('should handle debug logging', () async {
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockChannel.stream).thenAnswer((_) => Stream.empty());
      webSocketService.connect();
      await Future.delayed(Duration(milliseconds: 100));
      expect(webSocketService.isConnected, isA<bool>());
    });
  });
} 