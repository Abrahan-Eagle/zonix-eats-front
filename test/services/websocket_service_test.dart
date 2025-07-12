import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zonix/features/services/websocket_service.dart';
import 'package:zonix/config/app_config.dart';

import 'websocket_service_test.mocks.dart';

@GenerateMocks([WebSocketChannel])
void main() {
  group('WebSocketService Tests', () {
    late WebSocketService webSocketService;
    late MockWebSocketChannel mockChannel;

    setUp(() {
      webSocketService = WebSocketService();
      mockChannel = MockWebSocketChannel();
    });

    tearDown(() {
      webSocketService.disconnect();
    });

    test('should create singleton instance', () {
      final instance1 = WebSocketService();
      final instance2 = WebSocketService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should connect to WebSocket server', () async {
      // Arrange
      when(mockChannel.sink).thenReturn(StreamController());
      when(mockChannel.stream).thenReturn(Stream.empty());

      // Act
      final result = await webSocketService.connect();

      // Assert
      expect(result, isTrue);
      expect(webSocketService.isConnected, isTrue);
    });

    test('should handle connection error', () async {
      // Arrange
      when(mockChannel.sink).thenThrow(Exception('Connection failed'));

      // Act
      final result = await webSocketService.connect();

      // Assert
      expect(result, isFalse);
      expect(webSocketService.isConnected, isFalse);
    });

    test('should subscribe to channel', () async {
      // Arrange
      await webSocketService.connect();
      const channelName = 'test.channel';

      // Act
      final result = await webSocketService.subscribeToChannel(channelName);

      // Assert
      expect(result, isTrue);
      expect(webSocketService.subscribedChannels.contains(channelName), isTrue);
    });

    test('should unsubscribe from channel', () async {
      // Arrange
      await webSocketService.connect();
      const channelName = 'test.channel';
      await webSocketService.subscribeToChannel(channelName);

      // Act
      final result = await webSocketService.unsubscribeFromChannel(channelName);

      // Assert
      expect(result, isTrue);
      expect(webSocketService.subscribedChannels.contains(channelName), isFalse);
    });

    test('should handle incoming messages', () async {
      // Arrange
      await webSocketService.connect();
      const testMessage = {
        'type': 'test_event',
        'data': {'key': 'value'}
      };

      // Act
      webSocketService.messageStream?.add(testMessage);

      // Assert
      expect(webSocketService.messageStream, isNotNull);
    });

    test('should reconnect automatically on disconnect', () async {
      // Arrange
      await webSocketService.connect();
      webSocketService.maxReconnectAttempts = 3;

      // Act
      webSocketService.disconnect();
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(webSocketService.reconnectAttempts, greaterThan(0));
    });

    test('should handle message parsing', () {
      // Arrange
      const jsonString = '{"type": "test", "data": "value"}';

      // Act
      final parsed = webSocketService.parseMessage(jsonString);

      // Assert
      expect(parsed['type'], equals('test'));
      expect(parsed['data'], equals('value'));
    });

    test('should handle invalid JSON message', () {
      // Arrange
      const invalidJson = 'invalid json';

      // Act
      final parsed = webSocketService.parseMessage(invalidJson);

      // Assert
      expect(parsed, isNull);
    });

    test('should emit connection status changes', () async {
      // Arrange
      final statusChanges = <bool>[];
      webSocketService.connectionStatusStream?.listen(statusChanges.add);

      // Act
      await webSocketService.connect();
      webSocketService.disconnect();

      // Assert
      expect(statusChanges.length, greaterThan(0));
    });

    test('should handle ping/pong', () async {
      // Arrange
      await webSocketService.connect();

      // Act
      final pingResult = await webSocketService.ping();

      // Assert
      expect(pingResult, isTrue);
    });

    test('should get connection statistics', () {
      // Arrange
      webSocketService.messagesSent = 10;
      webSocketService.messagesReceived = 5;
      webSocketService.reconnectAttempts = 2;

      // Act
      final stats = webSocketService.getConnectionStats();

      // Assert
      expect(stats['messagesSent'], equals(10));
      expect(stats['messagesReceived'], equals(5));
      expect(stats['reconnectAttempts'], equals(2));
    });

    test('should clear connection statistics', () {
      // Arrange
      webSocketService.messagesSent = 10;
      webSocketService.messagesReceived = 5;

      // Act
      webSocketService.clearStats();

      // Assert
      expect(webSocketService.messagesSent, equals(0));
      expect(webSocketService.messagesReceived, equals(0));
    });

    test('should handle multiple channel subscriptions', () async {
      // Arrange
      await webSocketService.connect();
      const channels = ['channel1', 'channel2', 'channel3'];

      // Act
      for (final channel in channels) {
        await webSocketService.subscribeToChannel(channel);
      }

      // Assert
      expect(webSocketService.subscribedChannels.length, equals(3));
      for (final channel in channels) {
        expect(webSocketService.subscribedChannels.contains(channel), isTrue);
      }
    });

    test('should handle channel subscription error', () async {
      // Arrange
      await webSocketService.connect();
      const invalidChannel = '';

      // Act
      final result = await webSocketService.subscribeToChannel(invalidChannel);

      // Assert
      expect(result, isFalse);
    });

    test('should handle message sending', () async {
      // Arrange
      await webSocketService.connect();
      const testMessage = {'type': 'test', 'data': 'value'};

      // Act
      final result = await webSocketService.sendMessage(testMessage);

      // Assert
      expect(result, isTrue);
      expect(webSocketService.messagesSent, equals(1));
    });

    test('should handle message sending error', () async {
      // Arrange
      const testMessage = {'type': 'test', 'data': 'value'};

      // Act
      final result = await webSocketService.sendMessage(testMessage);

      // Assert
      expect(result, isFalse);
    });

    test('should handle reconnection with exponential backoff', () async {
      // Arrange
      webSocketService.maxReconnectAttempts = 3;
      webSocketService.baseReconnectDelay = 100;

      // Act
      webSocketService.disconnect();
      await Future.delayed(Duration(milliseconds: 500));

      // Assert
      expect(webSocketService.reconnectAttempts, greaterThan(0));
    });

    test('should respect max reconnection attempts', () async {
      // Arrange
      webSocketService.maxReconnectAttempts = 2;
      webSocketService.baseReconnectDelay = 50;

      // Act
      webSocketService.disconnect();
      await Future.delayed(Duration(milliseconds: 200));

      // Assert
      expect(webSocketService.reconnectAttempts, lessThanOrEqualTo(2));
    });

    test('should handle connection timeout', () async {
      // Arrange
      webSocketService.connectionTimeout = Duration(milliseconds: 100);

      // Act
      final result = await webSocketService.connect();

      // Assert
      expect(result, isFalse);
    });

    test('should handle heartbeat mechanism', () async {
      // Arrange
      await webSocketService.connect();
      webSocketService.heartbeatInterval = Duration(milliseconds: 100);

      // Act
      await Future.delayed(Duration(milliseconds: 150));

      // Assert
      expect(webSocketService.lastHeartbeat, isNotNull);
    });

    test('should handle connection status monitoring', () async {
      // Arrange
      final statusUpdates = <bool>[];
      webSocketService.connectionStatusStream?.listen(statusUpdates.add);

      // Act
      await webSocketService.connect();
      await Future.delayed(Duration(milliseconds: 50));
      webSocketService.disconnect();

      // Assert
      expect(statusUpdates.length, greaterThan(0));
    });

    test('should handle error logging', () {
      // Arrange
      const errorMessage = 'Test error message';

      // Act
      webSocketService.logError(errorMessage);

      // Assert
      // Verify that error was logged (implementation dependent)
      expect(webSocketService.lastError, equals(errorMessage));
    });

    test('should handle debug mode', () {
      // Arrange
      webSocketService.enableDebugLogs = true;

      // Act
      webSocketService.logDebug('Debug message');

      // Assert
      expect(webSocketService.enableDebugLogs, isTrue);
    });

    test('should handle connection URL configuration', () {
      // Arrange
      final localUrl = AppConfig.websocketUrlLocal;
      final prodUrl = AppConfig.websocketUrlProd;

      // Assert
      expect(localUrl, isNotEmpty);
      expect(prodUrl, isNotEmpty);
      expect(localUrl, contains('localhost'));
      expect(prodUrl, contains('wss://'));
    });

    test('should handle app configuration', () {
      // Arrange
      final appId = AppConfig.echoAppId;
      final appKey = AppConfig.echoKey;

      // Assert
      expect(appId, isNotEmpty);
      expect(appKey, isNotEmpty);
    });
  });
} 